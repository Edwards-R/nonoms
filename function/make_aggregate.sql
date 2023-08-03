CREATE OR REPLACE FUNCTION make_aggregate(
        level_id integer,
        source_id integer,
        author text,
        year integer
    )
    RETURNS integer
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    level RECORD;
    source RECORD;
    agg_id INT;
BEGIN
    -- Get the level details
    level = @extschema@.select_level(level_id);
    -- Get the source details
    EXECUTE format(
        'SELECT * FROM @extschema@.%I WHERE id = $1',
        level.name
    )
    USING source_id
    INTO source;
    --Make the aggregate
    EXECUTE format(
        'INSERT INTO @extschema@.%I (name, author, year, parent) VALUES ($1, $2, $3, $4) RETURNING id',
        level.name
    )
    USING source.name || ' agg', author, year, source.parent
    INTO agg_id;

    RETURN agg_id;
END;
$BODY$;