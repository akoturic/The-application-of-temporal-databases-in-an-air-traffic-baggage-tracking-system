CREATE OR REPLACE FUNCTION register_baggage_and_itinerary(
    p_passenger_id BIGINT,
    p_baggage_tag_id VARCHAR(10),
    p_flight_ids BIGINT[]
)
RETURNS BIGINT AS $$
DECLARE
    v_baggage_id BIGINT;
    flight_id BIGINT;
    segment_counter INT := 1;
BEGIN
    -- Kreiraj prtljagu
    INSERT INTO Baggage (baggage_tag_id, passenger_id)
    VALUES (p_baggage_tag_id, p_passenger_id)
    RETURNING baggage_id INTO v_baggage_id;

    -- Kreiraj plan puta
    IF p_flight_ids IS NOT NULL THEN
        FOREACH flight_id IN ARRAY p_flight_ids
        LOOP
            INSERT INTO BaggageItinerary (baggage_id, flight_id, segment_number)
            VALUES (v_baggage_id, flight_id, segment_counter);
            segment_counter := segment_counter + 1;
        END LOOP;
    END IF;
    
    RETURN v_baggage_id;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION log_baggage_status(
    p_baggage_tag_id VARCHAR(10),
    p_new_location_id BIGINT,
    p_new_status baggage_status,
    p_new_event_time TIMESTAMPTZ,
    p_new_flight_id BIGINT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_baggage_id BIGINT;
    v_new_history_id BIGINT;
BEGIN
    -- Pronađi baggage_id na temelju p_baggage_tag_id
    SELECT baggage_id INTO v_baggage_id
    FROM Baggage
    WHERE baggage_tag_id = p_baggage_tag_id;

    -- Ako prtljaga s tom oznakom ne postoji, prekini operaciju s greškom
    IF v_baggage_id IS NULL THEN
        RAISE EXCEPTION 'Prtljaga s oznakom % ne postoji.', p_baggage_tag_id;
    END IF;

    -- Zatvori prethodni, trenutno aktivni vremenski interval (ako postoji)
    UPDATE BaggageHistory
    SET validity_period = tstzrange(lower(validity_period), p_new_event_time)
    WHERE baggage_id = v_baggage_id
      AND upper(validity_period) IS NULL;

    -- Unesi novi, sada aktivni zapis u povijest
    INSERT INTO BaggageHistory (baggage_id, location_id, flight_id, status, validity_period)
    VALUES (
        v_baggage_id,
        p_new_location_id,
        p_new_flight_id,
        p_new_status,
        tstzrange(p_new_event_time, NULL)
    )
    RETURNING history_id INTO v_new_history_id;

    RETURN v_new_history_id;
END;
$$ LANGUAGE plpgsql;



