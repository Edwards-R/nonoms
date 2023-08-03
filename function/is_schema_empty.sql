CREATE OR REPLACE FUNCTION is_schema_empty(
    )
    RETURNS BOOLEAN
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    num_tables INT;
BEGIN
    num_tables=0;
    SELECT count(*) FROM information_schema.tables 
    WHERE table_schema = '@extschema@' INTO num_tables;

    IF num_tables>0 THEN
        return FALSE;
    END IF;

    -- Finally, all checks passed
    RETURN TRUE;
END;
$BODY$;