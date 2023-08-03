CREATE OR REPLACE FUNCTION select_child_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT * FROM @extschema@.rank WHERE major_parent = level_id AND id!=major_parent INTO result;
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;
