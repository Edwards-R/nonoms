CREATE OR REPLACE PROCEDURE update_children(
        IN level_id integer,
        IN input integer,
        IN output integer
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    author TEXT;
    year INT;
    c INT;
    level_name TEXT;
    level RECORD;
    child_level RECORD;
    f RECORD;

BEGIN
    -- Fetch the child level
    child_level = @extschema@.select_child_level(level_id);

    -- Check to see if one was fetched. Exit if no more levels
    IF child_level IS NULL THEN
        RETURN;
    END IF;

    -- Get the name of the level so we can find it in tables
    level = @extschema@.select_level(level_id);

    -- Check to see if the input is not current
    EXECUTE
        format('SELECT COUNT(*) FROM @extschema@.%I WHERE id = current AND id = ($1)', level.name)
        INTO c
        USING input
    ;

    -- If there's a current understanding, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Inputs may not contain current understandings';
    END IF;

    -- Check that the output is current
    EXECUTE
        format('SELECT COUNT(*) FROM @extschema@.%I WHERE id != current AND id = ($1)', level.name)
        INTO c
        USING output
    ;

    -- If it's a synonym, stop
    IF (c > 0) THEN
        RAISE EXCEPTION 'Output may not be a synonym';
    END IF;

    -- Get the author and year of the parent so that it propagates
    EXECUTE
        format('SELECT author, year FROM @extschema@.%I WHERE id = $1', level.name)
        INTO author, year
        USING output
    ;

    -- For each child
    FOR f in SELECT * FROM @extschema@.fetch_valid_children(level.id, input)

    LOOP
        -- Create the new understanding under the new parent and return the id
        SELECT @extschema@.create_understanding(child_level.id, output, f.name, author, year, null) INTO c;

        -- Update the old to direct to the new
        EXECUTE
        format('UPDATE @extschema@.%I SET current = $1 WHERE current = $2', child_level.name)
        USING c, f.id;

        -- Now update try to update the children
        CALL @extschema@.update_children(child_level.id, f.id, c);

    END LOOP;

END;
$BODY$;