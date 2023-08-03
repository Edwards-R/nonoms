CREATE OR REPLACE FUNCTION select_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT * FROM @extschema@.rank WHERE id = level_id INTO result;
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;