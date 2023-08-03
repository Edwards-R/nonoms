CREATE OR REPLACE FUNCTION extract_split_ids(
	    destinations @extschema@.split_result[]
    )
    RETURNS TABLE(
        id integer
    ) 
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT 
            unnest((y.x).children) as destination
        FROM (
            SELECT UNNEST(
                $1::@extschema@.split_result[]
            )
            as x
        ) as y'
    )
    USING destinations;

END;
$BODY$;