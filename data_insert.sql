-- Aerodromi
INSERT INTO Airport (iata_code, airport_name, city, country) VALUES
('ZAG','Franjo Tuđman Airport','Zagreb','Croatia'),
('FRA','Frankfurt Airport','Frankfurt','Germany'),
('AMS','Amsterdam Schiphol','Amsterdam','Netherlands'),
('LHR','London Heathrow','London','United Kingdom'),
('JFK','John F. Kennedy International','New York','United States'),
('CDG','Paris Charles de Gaulle','Paris','France');

-- PUTNICI
INSERT INTO Passenger (first_name, last_name) VALUES
('Ana','Kovač'),
('Emma','Johnson'),
('Marko','Horvat'),
('Sofia','Martínez'),
('Ivana','Petrović'),
('Noah','Schneider'),
('Luka','Novak'),
('Ava','Kowalska'),
('Petra','Babić'),
('Lucas','Dubois'),
('Nikola','Marić');

--LOKACIJE NA AERODROMIMA
INSERT INTO Location (airport_id, location_code, location_description)
VALUES (NULL, 'AIRCRAFT', 'Onboard Aircraft')
ON CONFLICT DO NOTHING;


WITH airports AS (
  SELECT a.airport_id, a.iata_code
  FROM Airport a
  WHERE a.iata_code IN ('ZAG','FRA','AMS','LHR','JFK','CDG')
),
locs AS (
  SELECT *
  FROM (VALUES
    -- Check-in counters
    ('CKI_01',     'Check-in Counter 01'),
    ('CKI_02',     'Check-in Counter 02'),
    ('CKI_12',     'Check-in Counter 12'),
    -- Sorting facilities
    ('SRT_DEP',    'Departure Sorting Facility'),
    ('SRT_ARR',    'Arrival Sorting Facility'),
    -- Gates (loading areas)
    ('GATE_A10',   'Loading Area Gate A10'),
    ('GATE_B22',   'Loading Area Gate B22'),
    -- Ramps (unloading areas)
    ('RAMP_C15',   'Unloading Area Ramp C15'),
    ('RAMP_E03',   'Unloading Area Ramp E03'),
    -- Baggage claim
    ('CLAIM_04',   'Baggage Claim Carousel 4'),
    ('CLAIM_12',   'Baggage Claim Carousel 12'),
    -- Lost & Found
    ('LNF_OFF',    'Lost and Found Office')
  ) AS t(code, description)
)
INSERT INTO Location (airport_id, location_code, location_description)
SELECT ap.airport_id, l.code, l.description
FROM airports ap
CROSS JOIN locs l
ON CONFLICT DO NOTHING;







