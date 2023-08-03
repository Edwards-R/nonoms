CREATE OR REPLACE FUNCTION fetch_valid_children(
        level_id integer,
        target_understanding integer
    )
    RETURNS TABLE(
        id integer, name text
    ) 
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    child_level RECORD;
BEGIN
    -- Get the level that has the direct parent of the given parent
    child_level = @extschema@.select_child_level(level_id);

    -- Return the ids of the valid children
    RETURN QUERY EXECUTE format(
        'SELECT x.id, x.name FROM (
            SELECT t.id, t.name, count(c.*) 
            FROM @extschema@.%I t 
            JOIN @extschema@.%I_composition c ON t.id = c.subject 
            WHERE t.id=t.current 
            AND t.parent = $1
            GROUP BY t.id
        ) as x
        WHERE count = 1',
        child_level.name,
        child_level.name
    )
    USING target_understanding
    ;
END;
$BODY$;