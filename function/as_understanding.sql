CREATE OR REPLACE FUNCTION as_understanding(
        name TEXT,
        author TEXT,
        year INT
    )
    RETURNS integer[]
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
   
BEGIN
    RETURN name || ': iso. ' || author || ': ' || year
END;
$BODY$;