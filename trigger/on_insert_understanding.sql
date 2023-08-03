-- This wont work as it doesn't know where to assign it
CREATE OR REPLACE FUNCTION on_insert_understanding()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
	BEGIN
		IF NEW.current IS NULL THEN
			NEW.current = NEW.id;
		END IF;
		RETURN NEW;
END
$BODY$;