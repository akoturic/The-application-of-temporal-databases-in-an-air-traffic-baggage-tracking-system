CREATE EXTENSION IF NOT EXISTS btree_gist;

SET TIME ZONE 'UTC';

-- kreiranje tipa podataka za status prtljage
CREATE TYPE baggage_status AS ENUM (
    'CHECKED_IN',
    'IN_SORTING_FACILITY',
    'LOADED',
    'IN_TRANSIT',
    'UNLOADED',
    'READY_FOR_PICKUP',
    'CLAIMED',
    'DELAYED',
    'LOST'
);

-- osnovne tablice
CREATE TABLE Passenger (
    passenger_id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL CHECK (length(trim(first_name)) > 0),
    last_name TEXT NOT NULL CHECK (length(trim(last_name)) > 0)
);

CREATE TABLE Airport (
    airport_id BIGSERIAL PRIMARY KEY,
    iata_code VARCHAR(3) UNIQUE NOT NULL CHECK (iata_code ~ '^[A-Z]{3}$'),
    airport_name TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL
);

CREATE TABLE Location (
    location_id BIGSERIAL PRIMARY KEY,
	airport_id BIGINT REFERENCES Airport(airport_id),
    location_code VARCHAR(20) NOT NULL CHECK (length(trim(location_code)) > 0),
    location_description TEXT
);


-- tablice ovisne o osnovnim tablicama
CREATE TABLE Flight (
    flight_id BIGSERIAL PRIMARY KEY,
    flight_number VARCHAR(6) NOT NULL CHECK (flight_number ~ '^[A-Z0-9]{2}[0-9]{1,4}$'),
    origin_airport_id BIGINT NOT NULL REFERENCES Airport(airport_id),
    destination_airport_id BIGINT NOT NULL REFERENCES Airport(airport_id),
    departure_time TIMESTAMPTZ NOT NULL,
    arrival_time TIMESTAMPTZ NOT NULL,
	CONSTRAINT flight_times_check CHECK (departure_time < arrival_time),
    CONSTRAINT flight_origin_destination_check CHECK (origin_airport_id <> destination_airport_id)
);


CREATE TABLE Baggage (
    baggage_id BIGSERIAL PRIMARY KEY,
    baggage_tag_id VARCHAR(10) UNIQUE NOT NULL CHECK (baggage_tag_id ~ '^[A-Z]{2}[0-9]{8}$'),
    passenger_id BIGINT NOT NULL REFERENCES Passenger(passenger_id)
);


CREATE TABLE BaggageItinerary (
    itinerary_id BIGSERIAL PRIMARY KEY,
    baggage_id BIGINT NOT NULL REFERENCES Baggage(baggage_id),
    flight_id BIGINT NOT NULL REFERENCES Flight(flight_id),
    segment_number INT NOT NULL CHECK (segment_number > 0),
    CONSTRAINT uq_baggage_segment UNIQUE (baggage_id, segment_number),
	CONSTRAINT uq_baggage_flight UNIQUE (baggage_id, flight_id)
);


-- Glavna, temporalna tablica
CREATE TABLE BaggageHistory (
    history_id BIGSERIAL PRIMARY KEY,
    baggage_id BIGINT NOT NULL REFERENCES Baggage(baggage_id),
    location_id BIGINT NOT NULL REFERENCES Location(location_id),
    flight_id BIGINT REFERENCES Flight(flight_id),
    status baggage_status NOT NULL,
    validity_period TSTZRANGE NOT NULL,
    CONSTRAINT excl_overlapping_baggage_history
    EXCLUDE USING GIST (baggage_id WITH =, validity_period WITH &&)
);

-- indeksi na vanjski kljucevima za ubrzanje JOIN operacije
CREATE INDEX ON BaggageItinerary (baggage_id);
CREATE INDEX ON BaggageItinerary (flight_id);

-- indeksi za ubrzavanje pretrage po cesto koristenim atributima
CREATE INDEX ON Flight (flight_number);
CREATE INDEX ON BaggageHistory (status);
CREATE INDEX ON BaggageHistory (flight_id);

-- jedinstveni parcijalni indeksi
CREATE UNIQUE INDEX uq_location_per_airport
ON Location (airport_id, location_code)
WHERE airport_id IS NOT NULL;

CREATE UNIQUE INDEX uq_location_global
ON Location (location_code)
WHERE airport_id IS NULL;

CREATE UNIQUE INDEX uq_bh_one_open 
ON BaggageHistory(baggage_id) 
WHERE upper(validity_period) IS NULL;
