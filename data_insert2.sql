-- ========================================================================================================================
-- Prtljaga 1: direktan let ZAG -> FRA, '2025-08-25 09:10:00Z', '2025-08-25 10:40:00Z', 'OU416', 'OU01122334'  
-- ========================================================================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
    v_flight_id BIGINT;
    v_baggage_id BIGINT;
    v_zag_airport_id BIGINT;
    v_fra_airport_id BIGINT;
    v_zag_cki_loc_id BIGINT;
    v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
    v_fra_ramp_loc_id BIGINT;
    v_fra_claim_loc_id BIGINT;

BEGIN

    -- Dohvati ID za putnika
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Marko' AND last_name = 'Horvat';
    
    -- Dohvati ID-jeve za aerodrome
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT airport_id INTO v_fra_airport_id FROM Airport WHERE iata_code = 'FRA';

    -- Dohvati ID-jeve za ključne lokacije
    SELECT location_id INTO v_zag_cki_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_01';
    SELECT location_id INTO v_zag_srt_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_zag_gate_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_A10';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';
    SELECT location_id INTO v_fra_ramp_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'RAMP_C15';
    SELECT location_id INTO v_fra_claim_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'CLAIM_04';

    RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';


    -- Unos leta ZAG -> FRA
    INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
    VALUES ('OU416', v_zag_airport_id, v_fra_airport_id, '2025-08-25 09:10:00Z', '2025-08-25 10:40:00Z')
    RETURNING flight_id INTO v_flight_id;


    -- Unos prtljage i njenog plana puta
    SELECT register_baggage_and_itinerary(
        p_passenger_id := v_passenger_id,
        p_baggage_tag_id := 'OU01122334',
        p_flight_ids := ARRAY[v_flight_id]
    ) INTO v_baggage_id;

    RAISE NOTICE 'Kreiran let i prtljaga s planom puta.';

   -- Unos kronološkog tijeka događaja u BaggageHistory
    PERFORM log_baggage_status(p_baggage_tag_id := 'OU01122334', p_new_location_id := v_zag_cki_loc_id,
	p_new_status := 'CHECKED_IN', p_new_event_time := '2025-08-25 07:30:00Z');
    PERFORM log_baggage_status('OU01122334', v_zag_srt_loc_id,   'IN_SORTING_FACILITY', '2025-08-25 07:45:00Z');
    PERFORM log_baggage_status('OU01122334', v_zag_gate_loc_id,  'LOADED',              '2025-08-25 08:40:00Z', v_flight_id);
    PERFORM log_baggage_status('OU01122334', v_aircraft_loc_id,  'IN_TRANSIT',          '2025-08-25 09:10:00Z', v_flight_id);
    PERFORM log_baggage_status('OU01122334', v_fra_ramp_loc_id,  'UNLOADED',            '2025-08-25 10:45:00Z', v_flight_id);
    PERFORM log_baggage_status('OU01122334', v_fra_claim_loc_id, 'READY_FOR_PICKUP',    '2025-08-25 11:05:00Z');
    PERFORM log_baggage_status('OU01122334', v_fra_claim_loc_id, 'CLAIMED',             '2025-08-25 11:12:00Z');

    RAISE NOTICE 'Uspješno uneseno.';

END $$;



-- ============================================================================================================
-- Prtljaga 2: direktan let ZAG -> FRA, '2025-08-25 09:10:00Z', '2025-08-25 10:40:00Z', 'OU416', 'OU55667788'
-- ============================================================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
    v_flight_id BIGINT;
    v_baggage_id BIGINT;
    v_zag_airport_id BIGINT;
    v_fra_airport_id BIGINT;
    v_zag_cki_loc_id BIGINT;
    v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
    v_fra_ramp_loc_id BIGINT;
    v_fra_claim_loc_id BIGINT;

BEGIN  
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Emma' AND last_name = 'Johnson';
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT airport_id INTO v_fra_airport_id FROM Airport WHERE iata_code = 'FRA';
    SELECT flight_id INTO v_flight_id FROM Flight WHERE flight_number = 'OU416' AND departure_time = '2025-08-25 09:10:00Z'::timestamptz;
    SELECT location_id INTO v_zag_cki_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_02'; -- Koristi drugi šalter
    SELECT location_id INTO v_zag_srt_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_zag_gate_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_A10';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';
    SELECT location_id INTO v_fra_ramp_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'RAMP_C15';
    SELECT location_id INTO v_fra_claim_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'CLAIM_04';

    RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';

    -- Unos prtljage i njenog plana puta    
    SELECT register_baggage_and_itinerary(
        p_passenger_id := v_passenger_id,
        p_baggage_tag_id := 'OU55667788',
        p_flight_ids := ARRAY[v_flight_id]
    ) INTO v_baggage_id;

    RAISE NOTICE 'Kreiran prtljaga s planom puta.';

   -- Unos kronološkog tijeka događaja u BaggageHistory
    PERFORM log_baggage_status(p_baggage_tag_id := 'OU55667788', p_new_location_id := v_zag_cki_loc_id, p_new_status := 'CHECKED_IN',
        p_new_event_time := '2025-08-25 07:35:00Z');
    PERFORM log_baggage_status('OU55667788', v_zag_srt_loc_id,   'IN_SORTING_FACILITY', '2025-08-25 07:52:00Z');
    PERFORM log_baggage_status('OU55667788', v_zag_gate_loc_id,  'LOADED',              '2025-08-25 08:45:00Z', v_flight_id);
    PERFORM log_baggage_status('OU55667788', v_aircraft_loc_id,  'IN_TRANSIT',          '2025-08-25 09:10:00Z', v_flight_id);
    PERFORM log_baggage_status('OU55667788', v_fra_ramp_loc_id,  'UNLOADED',            '2025-08-25 10:45:00Z', v_flight_id);
    PERFORM log_baggage_status('OU55667788', v_fra_claim_loc_id, 'READY_FOR_PICKUP',    '2025-08-25 11:08:00Z');
    PERFORM log_baggage_status('OU55667788', v_fra_claim_loc_id, 'CLAIMED',             '2025-08-25 11:15:00Z');

    RAISE NOTICE 'Uspješno uneseno.';

END $$;




-- =======================================================================================================================
-- Prtljaga 3: presjedanje, ZAG - FRA - JFK, 'OU416', '2025-08-25 09:10:00Z', 'LH404', '2025-08-25 15:00:00Z', 'OU77889900'
-- =======================================================================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
    v_flight_id_1 BIGINT; -- Za prvi let (OU416)
    v_flight_id_2 BIGINT; -- Za drugi let (FRA -> JFK)
    v_baggage_id BIGINT;
	
    v_zag_airport_id BIGINT;
    v_fra_airport_id BIGINT;
    v_jfk_airport_id BIGINT;

    v_zag_cki_loc_id BIGINT;
    v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
    v_fra_ramp_loc_id BIGINT;
    v_fra_connect_loc_id BIGINT;
    v_fra_gate_loc_id BIGINT;
    v_jfk_ramp_loc_id BIGINT;
    v_jfk_claim_loc_id BIGINT;

BEGIN
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Ana' AND last_name = 'Kovač';  
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT airport_id INTO v_fra_airport_id FROM Airport WHERE iata_code = 'FRA';
    SELECT airport_id INTO v_jfk_airport_id FROM Airport WHERE iata_code = 'JFK';
    SELECT flight_id INTO v_flight_id_1 FROM Flight WHERE flight_number = 'OU416' AND departure_time = '2025-08-25 09:10:00Z'::timestamptz;
    SELECT location_id INTO v_zag_cki_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_12';
    SELECT location_id INTO v_zag_srt_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_zag_gate_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_A10';
    SELECT location_id INTO v_fra_ramp_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'RAMP_C15';
    SELECT location_id INTO v_fra_connect_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'SRT_ARR';
    SELECT location_id INTO v_fra_gate_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'GATE_B22';
    SELECT location_id INTO v_jfk_ramp_loc_id FROM Location WHERE airport_id = v_jfk_airport_id AND location_code = 'RAMP_E03';
    SELECT location_id INTO v_jfk_claim_loc_id FROM Location WHERE airport_id = v_jfk_airport_id AND location_code = 'CLAIM_12';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';

    RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';
	

    --Unos leta (FRA -> JFK)
    INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
    VALUES ('LH404', v_fra_airport_id, v_jfk_airport_id, '2025-08-25 15:00:00Z', '2025-08-25 23:45:00Z')
    RETURNING flight_id INTO v_flight_id_2;

    -- Unos prtljage i njenog plana puta
    SELECT register_baggage_and_itinerary(
        p_passenger_id := v_passenger_id,
        p_baggage_tag_id := 'OU77889900',
        p_flight_ids := ARRAY[v_flight_id_1, v_flight_id_2]
    ) INTO v_baggage_id;

    RAISE NOTICE 'Kreiran let i prtljaga s planom puta.';

   -- Unos kronološkog tijeka događaja u BaggageHistory
    PERFORM log_baggage_status('OU77889900', v_zag_cki_loc_id,     'CHECKED_IN',          '2025-08-25 07:40:00Z');
    PERFORM log_baggage_status('OU77889900', v_zag_srt_loc_id,     'IN_SORTING_FACILITY', '2025-08-25 07:55:00Z');
    PERFORM log_baggage_status('OU77889900', v_zag_gate_loc_id,    'LOADED',              '2025-08-25 08:50:00Z', v_flight_id_1);
    PERFORM log_baggage_status('OU77889900', v_aircraft_loc_id,    'IN_TRANSIT',          '2025-08-25 09:10:00Z', v_flight_id_1);
    PERFORM log_baggage_status('OU77889900', v_fra_ramp_loc_id,    'UNLOADED',            '2025-08-25 10:45:00Z', v_flight_id_1);
    PERFORM log_baggage_status('OU77889900', v_fra_connect_loc_id, 'IN_SORTING_FACILITY', '2025-08-25 11:00:00Z'); -- Presjedanje
    PERFORM log_baggage_status('OU77889900', v_fra_gate_loc_id,    'LOADED',              '2025-08-25 14:30:00Z', v_flight_id_2);
    PERFORM log_baggage_status('OU77889900', v_aircraft_loc_id,    'IN_TRANSIT',          '2025-08-25 15:00:00Z', v_flight_id_2);
    PERFORM log_baggage_status('OU77889900', v_jfk_ramp_loc_id,    'UNLOADED',            '2025-08-25 23:50:00Z', v_flight_id_2);
    PERFORM log_baggage_status('OU77889900', v_jfk_claim_loc_id,   'READY_FOR_PICKUP',    '2025-08-26 00:15:00Z');
    PERFORM log_baggage_status('OU77889900', v_jfk_claim_loc_id,   'CLAIMED',             '2025-08-26 00:25:00Z');

    RAISE NOTICE 'Uspješno uneseno.';

END $$;



-- ====================================================================
-- Prtljaga 4: prtljaga na krivom letu
-- ====================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
	v_baggage_id BIGINT;
	v_flight_id_planned BIGINT;
    v_flight_id_actual BIGINT;
	v_zag_airport_id BIGINT;
	v_cdg_airport_id BIGINT;
    v_lhr_airport_id BIGINT;
	v_zag_cki_loc_id BIGINT;
	v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id_lhr BIGINT;
	v_aircraft_loc_id BIGINT;
	v_lhr_ramp_loc_id BIGINT;
    v_lhr_srt_loc_id BIGINT;
	v_lhr_lnf_loc_id BIGINT;
BEGIN
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Ivana' AND last_name = 'Petrović';
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT airport_id INTO v_cdg_airport_id FROM Airport WHERE iata_code = 'CDG';
    SELECT airport_id INTO v_lhr_airport_id FROM Airport WHERE iata_code = 'LHR';
    SELECT location_id INTO v_zag_cki_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_01';
    SELECT location_id INTO v_zag_srt_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_zag_gate_loc_id_lhr FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_B22';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';
    SELECT location_id INTO v_lhr_ramp_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'RAMP_E03';
    SELECT location_id INTO v_lhr_srt_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'SRT_ARR';
    SELECT location_id INTO v_lhr_lnf_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'LNF_OFF';

	RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';	
	
    -- Unos leta
    INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
    VALUES ('AF1561', v_zag_airport_id, v_cdg_airport_id, '2025-08-25 16:00:00Z', '2025-08-25 18:00:00Z')
    RETURNING flight_id INTO v_flight_id_planned;

    INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
    VALUES ('BA849', v_zag_airport_id, v_lhr_airport_id, '2025-08-25 16:10:00Z', '2025-08-25 17:40:00Z')
    RETURNING flight_id INTO v_flight_id_actual;

    -- Unos prtljage i njenog plana puta
    SELECT register_baggage_and_itinerary(
		p_passenger_id := v_passenger_id,
		p_baggage_tag_id := 'AF11122233',
		p_flight_ids := ARRAY[v_flight_id_planned])
	INTO v_baggage_id;

	RAISE NOTICE 'Kreiran let i prtljaga s planom puta.';
	
   -- Unos kronološkog tijeka događaja u BaggageHistory
    PERFORM log_baggage_status('AF11122233', v_zag_cki_loc_id, 'CHECKED_IN', '2025-08-25 14:00:00Z');
    PERFORM log_baggage_status('AF11122233', v_zag_srt_loc_id, 'IN_SORTING_FACILITY', '2025-08-25 14:15:00Z');
    PERFORM log_baggage_status('AF11122233', v_zag_gate_loc_id_lhr, 'LOADED', '2025-08-25 15:45:00Z', v_flight_id_actual); -- prtljaga ukrcana na krivi avion
    PERFORM log_baggage_status('AF11122233', v_aircraft_loc_id, 'IN_TRANSIT', '2025-08-25 16:10:00Z', v_flight_id_actual);
    PERFORM log_baggage_status('AF11122233', v_lhr_ramp_loc_id, 'UNLOADED', '2025-08-25 17:45:00Z', v_flight_id_actual);
    PERFORM log_baggage_status('AF11122233', v_lhr_srt_loc_id, 'IN_SORTING_FACILITY', '2025-08-25 18:00:00Z');
    PERFORM log_baggage_status('AF11122233', v_lhr_lnf_loc_id, 'DELAYED', '2025-08-25 18:30:00Z');

    RAISE NOTICE 'Uspješno uneseno.';
END $$;


-- ====================================================================
-- Prtljaga 5: zakašnjela prtljaga 
-- ====================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
	v_baggage_id BIGINT;
	v_flight_id BIGINT;
    v_ams_airport_id BIGINT;
	v_zag_airport_id BIGINT;
    v_ams_cki_loc_id BIGINT;
	v_ams_srt_loc_id BIGINT;
	v_ams_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
	v_zag_ramp_loc_id BIGINT;
	v_zag_lnf_loc_id BIGINT;
BEGIN
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Luka' AND last_name = 'Novak';
    SELECT airport_id INTO v_ams_airport_id FROM Airport WHERE iata_code = 'AMS';
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT location_id INTO v_ams_cki_loc_id FROM Location WHERE airport_id = v_ams_airport_id AND location_code = 'CKI_01';
    SELECT location_id INTO v_ams_srt_loc_id FROM Location WHERE airport_id = v_ams_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_ams_gate_loc_id FROM Location WHERE airport_id = v_ams_airport_id AND location_code = 'GATE_B22';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';
    SELECT location_id INTO v_zag_ramp_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'RAMP_C15';
    SELECT location_id INTO v_zag_lnf_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'LNF_OFF';

	RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';

    -- Unos leta
    INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
    VALUES ('KL1943', v_ams_airport_id, v_zag_airport_id, '2025-08-25 20:30:00Z', '2025-08-25 22:20:00Z')
    RETURNING flight_id INTO v_flight_id;

    -- Unos prtljage i njenog plana puta
    SELECT register_baggage_and_itinerary(
		p_passenger_id := v_passenger_id,
		p_baggage_tag_id := 'KL33445566',
		p_flight_ids := ARRAY[v_flight_id]
	) INTO v_baggage_id;

	RAISE NOTICE 'Kreiran let i prtljaga s planom puta.';
	
	-- Unos kronološkog tijeka događaja u BaggageHistory
	PERFORM log_baggage_status('KL33445566', v_ams_cki_loc_id, 'CHECKED_IN', '2025-08-25 18:30:00Z');
    PERFORM log_baggage_status('KL33445566', v_ams_srt_loc_id, 'IN_SORTING_FACILITY', '2025-08-25 18:45:00Z');
    PERFORM log_baggage_status('KL33445566', v_ams_gate_loc_id, 'LOADED', '2025-08-25 20:00:00Z', v_flight_id);
    PERFORM log_baggage_status('KL33445566', v_aircraft_loc_id, 'IN_TRANSIT', '2025-08-25 20:30:00Z', v_flight_id);
    PERFORM log_baggage_status('KL33445566', v_zag_ramp_loc_id, 'UNLOADED', '2025-08-25 22:25:00Z', v_flight_id);
    PERFORM log_baggage_status('KL33445566', v_zag_lnf_loc_id, 'DELAYED', '2025-08-25 23:30:00Z'); --putnik prijavljuje prtljagu koja nije stigla

    RAISE NOTICE 'Uspješno uneseno.';
END $$;

--=================================================================
--Prtljaga 6: pogresan ukrcaj, ZAG -> FRA -> JFK (LHR - greska)
--=================================================================
DO $$
DECLARE
	v_passenger_id BIGINT;
	v_baggage_id BIGINT;
	
	v_zag_airport_id BIGINT;
	v_fra_airport_id BIGINT;
	v_jfk_airport_id BIGINT;
	v_lhr_airport_id BIGINT;
	
	v_zag_cki_loc_id BIGINT;
	v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
	
    v_fra_ramp_loc_id BIGINT;
	v_fra_connect_loc_id BIGINT;
	v_fra_gate_loc_id BIGINT;
	
	v_lhr_ramp_loc_id BIGINT;
	v_lhr_srt_loc_id BIGINT;
	v_lhr_lnf_loc_id BIGINT;
	
	v_flight_id_1 BIGINT;
	v_flight_id_2_planned BIGINT;
	v_flight_id_2_actual BIGINT;
BEGIN
	SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Sofia' AND last_name = 'Martínez';
	SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
	SELECT airport_id INTO v_fra_airport_id FROM Airport WHERE iata_code = 'FRA';
	SELECT airport_id INTO v_jfk_airport_id FROM Airport WHERE iata_code = 'JFK';
	SELECT airport_id INTO v_lhr_airport_id FROM Airport WHERE iata_code = 'LHR';
	SELECT location_id INTO v_zag_cki_loc_id  FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_12';
	SELECT location_id INTO v_zag_srt_loc_id  FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
	SELECT location_id INTO v_zag_gate_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_A10';
	SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';	
	SELECT location_id INTO v_fra_ramp_loc_id    FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'RAMP_C15';
	SELECT location_id INTO v_fra_connect_loc_id FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'SRT_ARR';
	SELECT location_id INTO v_fra_gate_loc_id    FROM Location WHERE airport_id = v_fra_airport_id AND location_code = 'GATE_B22';
	SELECT location_id INTO v_lhr_ramp_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'RAMP_E03';
	SELECT location_id INTO v_lhr_srt_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'SRT_ARR';
    SELECT location_id INTO v_lhr_lnf_loc_id FROM Location WHERE airport_id = v_lhr_airport_id AND location_code = 'LNF_OFF';

	RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';
	
	-- 1. let
	SELECT flight_id INTO v_flight_id_1 FROM Flight 
	WHERE flight_number = 'OU416' AND departure_time = '2025-08-25 09:10:00Z'::timestamptz;

	-- 2. let (planirani)
	SELECT flight_id INTO v_flight_id_2_planned FROM Flight 
	WHERE flight_number = 'LH404' AND departure_time = '2025-08-25 15:00:00Z'::timestamptz;
		
	-- Unos 2. leta (krivo ukrcano)
	INSERT INTO Flight (flight_number, origin_airport_id, destination_airport_id, departure_time, arrival_time)
	VALUES ('BA849', v_fra_airport_id, v_lhr_airport_id, '2025-08-25 15:10:00Z', '2025-08-25 16:10:00Z')
	RETURNING flight_id INTO v_flight_id_2_actual;

	-- Unos prtljage i njenog plana puta
	SELECT register_baggage_and_itinerary(
		p_passenger_id := v_passenger_id,
		p_baggage_tag_id := 'OU44556677',
	    p_flight_ids := ARRAY[v_flight_id_1,
		v_flight_id_2_planned]
		) INTO v_baggage_id;

	RAISE NOTICE 'Kreiran let i prtljaga s planom puta.';
	
	-- Unos kronološkog tijeka događaja u BaggageHistory
	PERFORM log_baggage_status('OU44556677', v_zag_cki_loc_id,     'CHECKED_IN',            '2025-08-25 07:50:00Z');
    PERFORM log_baggage_status('OU44556677', v_zag_srt_loc_id,     'IN_SORTING_FACILITY',   '2025-08-25 08:05:00Z');
    PERFORM log_baggage_status('OU44556677', v_zag_gate_loc_id,    'LOADED',                '2025-08-25 08:52:00Z', v_flight_id_1);
    PERFORM log_baggage_status('OU44556677', v_aircraft_loc_id,    'IN_TRANSIT',            '2025-08-25 09:10:00Z', v_flight_id_1);
	PERFORM log_baggage_status('OU44556677', v_fra_ramp_loc_id,	   'UNLOADED',              '2025-08-25 10:45:00Z', v_flight_id_1);
	PERFORM log_baggage_status('OU44556677', v_fra_connect_loc_id, 'IN_SORTING_FACILITY',   '2025-08-25 11:05:00Z');
	PERFORM log_baggage_status('OU44556677', v_fra_gate_loc_id,    'LOADED',     			'2025-08-25 14:40:00Z', v_flight_id_2_actual);
	PERFORM log_baggage_status('OU44556677', v_aircraft_loc_id,    'IN_TRANSIT', 			'2025-08-25 15:10:00Z', v_flight_id_2_actual);
	PERFORM log_baggage_status('OU44556677', v_lhr_ramp_loc_id,    'UNLOADED',   			'2025-08-25 16:15:00Z', v_flight_id_2_actual);
	PERFORM log_baggage_status('OU44556677', v_lhr_srt_loc_id,     'IN_SORTING_FACILITY',	'2025-08-25 16:25:00Z');
	PERFORM log_baggage_status('OU44556677', v_lhr_lnf_loc_id,     'DELAYED', 				'2025-08-25 16:50:00Z');
	
	RAISE NOTICE 'Uspješno uneseno.';
END $$;



-- ==================================================================================================
-- Prtljaga 7: kasni ukrcaj, let AF1561
-- ==================================================================================================
DO $$
DECLARE
    v_passenger_id BIGINT;
    v_flight_id BIGINT;
    v_baggage_id BIGINT;
    v_zag_airport_id BIGINT;
    v_cdg_airport_id BIGINT;
    v_zag_cki_loc_id BIGINT;
    v_zag_srt_loc_id BIGINT;
    v_zag_gate_loc_id BIGINT;
    v_aircraft_loc_id BIGINT;
    v_cdg_ramp_loc_id BIGINT;
    v_cdg_claim_loc_id BIGINT;

BEGIN
    SELECT airport_id INTO v_zag_airport_id FROM Airport WHERE iata_code = 'ZAG';
    SELECT airport_id INTO v_cdg_airport_id FROM Airport WHERE iata_code = 'CDG';
    SELECT passenger_id INTO v_passenger_id FROM Passenger WHERE first_name = 'Petra' AND last_name = 'Babić';
    SELECT location_id INTO v_zag_cki_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'CKI_02';
    SELECT location_id INTO v_zag_srt_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'SRT_DEP';
    SELECT location_id INTO v_zag_gate_loc_id FROM Location WHERE airport_id = v_zag_airport_id AND location_code = 'GATE_B22';
    SELECT location_id INTO v_aircraft_loc_id FROM Location WHERE location_code = 'AIRCRAFT';
    SELECT location_id INTO v_cdg_ramp_loc_id FROM Location WHERE airport_id = v_cdg_airport_id AND location_code = 'RAMP_C15';
    SELECT location_id INTO v_cdg_claim_loc_id FROM Location WHERE airport_id = v_cdg_airport_id AND location_code = 'CLAIM_04';
	SELECT flight_id INTO v_flight_id FROM Flight WHERE flight_number = 'AF1561' AND departure_time = '2025-08-25 16:00:00Z'::timestamptz;

    RAISE NOTICE 'Dohvaćeni svi potrebni ID-jevi.';

    -- Unos prtljage i njenog plana puta
    SELECT register_baggage_and_itinerary(
        p_passenger_id := v_passenger_id,
        p_baggage_tag_id := 'AF98765432', 
        p_flight_ids := ARRAY[v_flight_id]
    ) INTO v_baggage_id;

    RAISE NOTICE 'Kreirana prtljaga s planom puta.';

    -- Unos kronološkog tijeka događaja u BaggageHistory
    PERFORM log_baggage_status('AF98765432', v_zag_cki_loc_id,   'CHECKED_IN',          '2025-08-25 14:45:00Z');
    PERFORM log_baggage_status('AF98765432', v_zag_srt_loc_id,   'IN_SORTING_FACILITY', '2025-08-25 15:15:00Z');
    PERFORM log_baggage_status('AF98765432', v_zag_gate_loc_id,  'LOADED',              '2025-08-25 16:05:00Z', v_flight_id);
    PERFORM log_baggage_status('AF98765432', v_aircraft_loc_id,  'IN_TRANSIT',          '2025-08-25 16:10:00Z', v_flight_id);
    PERFORM log_baggage_status('AF98765432', v_cdg_ramp_loc_id,  'UNLOADED',            '2025-08-25 18:15:00Z', v_flight_id);
    PERFORM log_baggage_status('AF98765432', v_cdg_claim_loc_id, 'READY_FOR_PICKUP',    '2025-08-25 18:35:00Z');
    PERFORM log_baggage_status('AF98765432', v_cdg_claim_loc_id, 'CLAIMED',             '2025-08-25 18:42:00Z');

    RAISE NOTICE 'Uspješno uneseno.';

END $$;


