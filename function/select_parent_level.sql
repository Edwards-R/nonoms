CREATE OR REPLACE FUNCTION select_parent_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT t2.*
    FROM @extschema@.rank t
    JOIN @extschema@.rank t2 on t.major_parent = t2.id
    WHERE t.id = level_id
    INTO result;
    
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;