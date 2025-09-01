--Zabrana brisanja bilo kojeg retka u tablici BaggageHistory

CREATE OR REPLACE FUNCTION bh_no_delete() RETURNS TRIGGER AS $$
BEGIN
	RAISE EXCEPTION 'Deleting history rows is not allowed.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bh_no_delete BEFORE DELETE 
ON BaggageHistory
FOR EACH ROW
EXECUTE FUNCTION bh_no_delete();

--Zabrana azuriranja bilo kojeg retka u tablici BaggageHistory osim u slucaju zatvaranja perioda

CREATE OR REPLACE FUNCTION bh_no_update() RETURNS TRIGGER AS $$
BEGIN
	IF upper(OLD.validity_period) IS NOT NULL THEN
		RAISE EXCEPTION 'Historical rows are immutable.';
	END IF;
	
	IF NEW.baggage_id IS DISTINCT FROM OLD.baggage_id OR
	   NEW.location_id IS DISTINCT FROM OLD.location_id OR
	   NEW.flight_id IS DISTINCT FROM OLD.flight_id OR
	   NEW.status IS DISTINCT FROM OLD.status OR
	   lower(NEW.validity_period) IS DISTINCT FROM lower(OLD.validity_period) THEN
		RAISE EXCEPTION 'Only closing the active interval is allowed; other fields are immutable';
	END IF;

	IF upper(NEW.validity_period) IS NULL THEN
		RAISE EXCEPTION 'Only closing the active interval is allowed';
	END IF;

	IF lower(NEW.validity_period) >= upper(NEW.validity_period) THEN
			RAISE  EXCEPTION 'Upper bound must be greater than start time';
	END IF;
	
	RETURN NEW;
	
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bh_no_update BEFORE UPDATE
	ON BaggageHistory
	FOR EACH ROW
	EXECUTE FUNCTION bh_no_update();