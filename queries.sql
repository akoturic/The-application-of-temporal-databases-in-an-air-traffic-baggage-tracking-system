--=====================================
-- UPIT 1: Trenutno stanje prtljage
--=====================================
SELECT
	b.baggage_tag_id AS "Oznaka prtljage",
	bh.status AS "Trenutni status",
	l.location_description AS "Trenutna lokacija",
	COALESCE(a.iata_code, 'N/A') AS "Aerodrom",
	to_char(lower(bh.validity_period), 'YYYY-MM-DD HH24:MI') AS "Vrijeme statusa"
FROM
	BaggageHistory bh
JOIN Baggage b ON bh.baggage_id = b.baggage_id
JOIN Location l ON bh.location_id = l.location_id
LEFT JOIN Airport a ON l.airport_id = a.airport_id
WHERE
	upper(bh.validity_period) IS NULL -- Samo trenutno važeći status
	AND b.baggage_tag_id = 'OU77889900'; -- Ovdje unesite željenu oznaku prtljage

--==================================================================================================
--UPIT 2: Point-in-Time - Status prtljage u određenom trenutku
--==================================================================================================
SELECT
	b.baggage_tag_id AS "Oznaka prtljage",
	-- Prikazujemo traženo vrijeme radi jasnoće u rezultatu
	to_char('2025-08-25 16:00:00'::TIMESTAMPTZ, 'YYYY-MM-DD HH24:MI:SS') AS "Traženo vrijeme",
	bh.status AS "Status u traženo vrijeme",
	l.location_description AS "Lokacija",
	COALESCE(a.iata_code, '') AS "Aerodrom",
	COALESCE(f.flight_number, '') AS "Let"
FROM
	BaggageHistory bh
JOIN Baggage b ON bh.baggage_id = b.baggage_id
JOIN Location l ON bh.location_id = l.location_id
LEFT JOIN Airport a ON l.airport_id = a.airport_id
LEFT JOIN Flight f ON bh.flight_id = f.flight_id
WHERE
	b.baggage_tag_id = 'OU77889900'
	AND bh.validity_period @> '2025-08-25 16:00:00'::TIMESTAMPTZ; 


--=========================================================
-- UPIT 3: Praćenje prtljage, rekonstrukcija puta prtljage
--=========================================================
SELECT
	to_char(lower(bh.validity_period), 'YYYY-MM-DD HH24:MI') AS "Vrijeme",
    bh.status AS "Status",
    l.location_description AS "Lokacija",
    COALESCE(a.iata_code || ' (' || a.airport_name || ')', '') AS "Aerodrom",
    COALESCE(f.flight_number || ' (' || origin_a.iata_code || ' -> ' || dest_a.iata_code || ')', '') AS "Let"
FROM 
    BaggageHistory bh
JOIN Baggage b ON bh.baggage_id = b.baggage_id
JOIN Location l ON bh.location_id = l.location_id
LEFT JOIN Airport a ON l.airport_id = a.airport_id
LEFT JOIN Flight f ON bh.flight_id = f.flight_id
LEFT JOIN Airport origin_a ON f.origin_airport_id = origin_a.airport_id
LEFT JOIN Airport dest_a ON f.destination_airport_id = dest_a.airport_id
WHERE b.baggage_tag_id = 'OU77889900' -- Unesite oznaku prtljage
ORDER BY lower(bh.validity_period) ASC;

--=====================================================================================================================================
-- UPIT 4: Usporedba planiranog i stvarno ukrcanog broja prtljage
--=====================================================================================================================================

WITH FlightsToday AS (
    -- Prvo definiramo opseg letova koji nas zanimaju
    SELECT flight_id, flight_number, departure_time, destination_airport_id
    FROM Flight
    WHERE origin_airport_id = (SELECT airport_id FROM Airport WHERE iata_code = 'FRA')
      AND date(departure_time) = '2025-08-25'
),
PlannedCount AS (
    -- Prebroji planiranu prtljagu po letu
    SELECT flight_id, count(baggage_id) AS planned_bags
    FROM BaggageItinerary
    WHERE flight_id IN (SELECT flight_id FROM FlightsToday)
    GROUP BY flight_id
),
ActualLoadedCount AS (
    -- Prebroji stvarno ukrcanu prtljagu po letu
    SELECT flight_id, count(DISTINCT baggage_id) AS actual_bags
    FROM BaggageHistory
    WHERE flight_id IN (SELECT flight_id FROM FlightsToday) AND status = 'LOADED'
    GROUP BY flight_id
),
ProblemCount AS (
    -- Prebroji prtljagu koja je trebala biti na letu, ali je završila kao DELAYED/LOST
    SELECT 
        bi.flight_id,
        count(*) AS problem_bags
    FROM BaggageItinerary bi
    -- Nađi trenutni status za svaku prtljagu
    JOIN (
        SELECT DISTINCT ON (baggage_id) baggage_id, status
        FROM BaggageHistory
        ORDER BY baggage_id, lower(validity_period) DESC
    ) AS CurrentStatuses ON bi.baggage_id = CurrentStatuses.baggage_id
    WHERE bi.flight_id IN (SELECT flight_id FROM FlightsToday)
      AND CurrentStatuses.status IN ('DELAYED', 'LOST')
    GROUP BY bi.flight_id
)
SELECT
    ft.flight_number AS "Let",
    to_char(ft.departure_time, 'HH24:MI') AS "Vrijeme polaska",
    dest_a.iata_code || ' (' || dest_a.airport_name || ')' AS "Odredište",
    COALESCE(pc.planned_bags, 0) AS "Planirano",
    COALESCE(alc.actual_bags, 0) AS "Ukrcano",
    COALESCE(alc.actual_bags, 0) - COALESCE(pc.planned_bags, 0) AS "Razlika",
    COALESCE(prob.problem_bags, 0) AS "DELAYED/LOST"
FROM
    FlightsToday ft
LEFT JOIN Airport dest_a ON ft.destination_airport_id = dest_a.airport_id
LEFT JOIN PlannedCount pc ON ft.flight_id = pc.flight_id
LEFT JOIN ActualLoadedCount alc ON ft.flight_id = alc.flight_id
LEFT JOIN ProblemCount prob ON ft.flight_id = prob.flight_id
ORDER BY
    ft.departure_time;


--==================================================================================================
--UPIT 5: Identifikacija neukrcane prtljage
--==================================================================================================
WITH
TargetFlight AS (
	-- Odaberi ciljani let po broju i datumu polaska
	SELECT flight_id
	FROM Flight
	WHERE flight_number = 'AF1561' AND date(departure_time) = '2025-08-25'
),
PlannedBaggage AS (
	-- Pronađi svu prtljagu koja je planirana za taj let
	SELECT bi.baggage_id
	FROM BaggageItinerary bi
	JOIN TargetFlight tf ON bi.flight_id = tf.flight_id
),
ActuallyLoadedBaggage AS (
	-- Pronađi svu prtljagu koja je stvarno ukrcana (status 'LOADED') na taj let
	SELECT bh.baggage_id
	FROM BaggageHistory bh
	JOIN TargetFlight tf ON bh.flight_id = tf.flight_id
	WHERE bh.status = 'LOADED'
)
SELECT
	b.baggage_tag_id AS "Oznaka prtljage",
	p.first_name || ' ' || p.last_name AS "Putnik"
FROM
	PlannedBaggage pb
JOIN Baggage b ON pb.baggage_id = b.baggage_id
JOIN Passenger p ON b.passenger_id = p.passenger_id
WHERE
	pb.baggage_id NOT IN (SELECT baggage_id FROM ActuallyLoadedBaggage);



--=========================================================
-- UPIT 6: Usporedba povijesti i plana puta prtljage
--=========================================================
WITH
EnrichedHistory AS (
    SELECT
        bh.baggage_id,
        bh.flight_id AS actual_flight_id,
        CASE 
            WHEN bh.flight_id IS NOT NULL THEN DENSE_RANK() OVER (PARTITION BY bh.baggage_id ORDER BY f.departure_time)
            ELSE NULL 
        END AS actual_segment_number,
        to_char(lower(bh.validity_period), 'YYYY-MM-DD HH24:MI') AS event_time,
        bh.status,
        l.location_description,
        a.iata_code AS airport_code,
        f.flight_number || ' (' || fo.iata_code || ' -> ' || fd.iata_code || ')' AS actual_flight_info
    FROM BaggageHistory bh
    JOIN Baggage b ON b.baggage_id = bh.baggage_id
    JOIN Location l ON l.location_id = bh.location_id
    LEFT JOIN Airport a ON a.airport_id = l.airport_id
    LEFT JOIN Flight f ON f.flight_id = bh.flight_id
    LEFT JOIN Airport fo ON fo.airport_id = f.origin_airport_id
    LEFT JOIN Airport fd ON fd.airport_id = f.destination_airport_id
    WHERE b.baggage_tag_id = 'AF11122233' -- Unesite oznaku prtljage
)
SELECT
    eh.event_time AS "Vrijeme",
    eh.status AS "Status",
    eh.location_description AS "Lokacija",
    COALESCE(eh.airport_code, '') AS "Aerodrom",
    COALESCE(eh.actual_flight_info, '') AS "Stvarni Let",
    COALESCE(p_flight.flight_number || ' (' || p_origin.iata_code || ' -> ' || p_dest.iata_code || ')','') AS "Planirani Let"
FROM
    EnrichedHistory eh
LEFT JOIN BaggageItinerary bi ON eh.baggage_id = bi.baggage_id AND eh.actual_segment_number = bi.segment_number
LEFT JOIN Flight p_flight ON bi.flight_id = p_flight.flight_id
LEFT JOIN Airport p_origin ON p_flight.origin_airport_id = p_origin.airport_id
LEFT JOIN Airport p_dest ON p_flight.destination_airport_id = p_dest.airport_id
ORDER BY eh.event_time ASC;

--==================================================================================================
--UPIT 7: Analiza efikasnosti procesa ukrcaja prtljage
--==================================================================================================
WITH
LastBagLoaded AS (
    -- Za svaki let, pronađi trenutak ukrcaja zadnje prtljage
    SELECT
        flight_id,
        MAX(lower(validity_period)) AS last_bag_load_time
    FROM BaggageHistory
    WHERE status = 'LOADED' AND flight_id IS NOT NULL
    GROUP BY flight_id
)
-- Usporedi to vrijeme s planiranim vremenom polaska za sve letove s odabranog aerodroma na dani datum
SELECT
    f.flight_number AS "Let",
    dest.iata_code AS "Odredište",
    to_char(f.departure_time, 'HH24:MI:SS') AS "Planirani polazak",
    COALESCE(to_char(lbl.last_bag_load_time, 'HH24:MI:SS'), 'Nema ukrcane prtljage') AS "Ukrcaj zadnje prtljage",
    -- Izracunaj razliku
    CASE
        WHEN lbl.last_bag_load_time IS NULL THEN 'N/A'
        WHEN f.departure_time >= lbl.last_bag_load_time THEN 
            to_char(f.departure_time - lbl.last_bag_load_time, 'MI"m "SS"s prije polaska"')
        ELSE
            to_char(lbl.last_bag_load_time - f.departure_time, 'MI"m "SS"s nakon polaska (kašnjenje)"')
    END AS "Status ukrcaja"
FROM
    Flight f
LEFT JOIN LastBagLoaded lbl ON f.flight_id = lbl.flight_id
JOIN Airport dest ON f.destination_airport_id = dest.airport_id
WHERE
    f.origin_airport_id = (SELECT airport_id FROM Airport WHERE iata_code = 'ZAG') -- Filtriraj po aerodromu
    AND date(f.departure_time) = '2025-08-25' -- Filtriraj po datumu
ORDER BY
    f.departure_time;


--==================================================================================================
-- UPIT 8: Analiza prosječnog čekanja prtljage
--==================================================================================================
WITH
ReadyForPickupEvents AS (
    -- Pronađi sve događaje kada je prtljaga bila spremna za preuzimanje, zajedno s aerodromom
    SELECT
        bh.baggage_id,
        lower(bh.validity_period) AS ready_time,
        l.airport_id
    FROM BaggageHistory bh
    JOIN Location l ON bh.location_id = l.location_id
    WHERE bh.status = 'READY_FOR_PICKUP'
),
LastFlightInfo AS (
    -- Za svaku prtljagu, pronađi ID zadnjeg leta na kojem je bila (zadnji 'UNLOADED' status)
    SELECT DISTINCT ON (baggage_id)
        baggage_id,
        flight_id
    FROM BaggageHistory
    WHERE status = 'UNLOADED'
    ORDER BY baggage_id, lower(validity_period) DESC
)
-- Spoji podatke o vremenu preuzimanja s podacima o letu i izračunaj prosjek po dolaznom aerodromu
SELECT
    a.iata_code || ' (' || a.airport_name || ')' AS "Aerodrom dolaska",
    to_char(AVG(rfp.ready_time - f.arrival_time), 'MI" minuta i "SS" sekundi"') AS "Prosjek čekanja prtljage"
FROM ReadyForPickupEvents rfp
JOIN LastFlightInfo lfi ON rfp.baggage_id = lfi.baggage_id
JOIN Flight f ON lfi.flight_id = f.flight_id
JOIN Airport a ON rfp.airport_id = a.airport_id
GROUP BY a.airport_id, a.iata_code, a.airport_name
ORDER BY AVG(rfp.ready_time - f.arrival_time) DESC;