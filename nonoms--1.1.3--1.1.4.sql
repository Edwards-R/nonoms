CREATE OR REPLACE PROCEDURE split_understanding(
        IN level_id integer,
        IN source integer,
        IN author text,
        IN year integer,
        IN destinations @extschema@.split_result[]
    )
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    level RECORD;
    child_level RECORD;
    subject RECORD;
    c INT;
    destination_understandings INT ARRAY;
    created_children INT ARRAY;
    understanding RECORD;
BEGIN
    -- Get the level details
    level = @extschema@.select_level(level_id);

    --Check that the level is not the capstone
    IF (level.id = level.major_parent) THEN
        RAISE EXCEPTION 'Cannot split the capstone rank';
    END IF;

    -- Check if the input is non-synonym
    -- We can save some time here by just grabbing everything - we'll need it later anyway
    EXECUTE
        format('SELECT * FROM @extschema@.%I WHERE id = $1', level.name)
        INTO subject
        USING source
    ;

    -- If synonym, fail
    IF (subject.id != subject.current) THEN
        RAISE EXCEPTION 'Input must be current and not a synonym';
    END IF;

    -- Check that there are > 1 destinations ie the split actually splits
    IF (ARRAY_LENGTH(destinations,1) < 2) THEN
        RAISE EXCEPTION 'There must be multiple destination outputs';
    END IF;

    -- Now things change based on what level is being modified
    -- If the level being modified is the lowest stored level, then there's not going to be any children to check
    -- Start by trying to fetch a child level
    child_level = @extschema@.select_child_level(level.id);

    IF child_level IS NOT NULL THEN
        -- Do all the checks for the children
        IF (@extschema@.split_child_check(level.id, subject.id, destinations) = FALSE) THEN
            RAISE EXCEPTION 'Error found in destinations';
        END IF;
        -- ALl children considered correct and accounted for after this point
    END IF;

    -- Move on to creating the split
    SELECT @extschema@.create_multiple_current_understandings(
        level_id,
        subject.parent,
        (
            SELECT array_agg(name) FROM UNNEST(destinations::@extschema@.split_result[])
        ),
        author,
        year
    ) INTO destination_understandings;

    -- Create the aggregate
    c = @extschema@.make_aggregate(level.id, subject.id, author, year);

    -- Assign the destination understandings as components of the aggregate
    EXECUTE format(
        'INSERT INTO @extschema@.%I_composition (subject, component) VALUES ($1, UNNEST($2))',
        level.name
    )
    USING c, destination_understandings;

    -- Update the source to direct to the aggregate
    EXECUTE format(
        'UPDATE @extschema@.%I SET current = $2 WHERE current = $1',
        level.name
    ) USING source, c;

    -- Now move on to working on the children of the destinations
    -- Exit if no child level
    IF child_level IS NULL THEN
        RETURN;
    END IF;

    /* 
     * There are children to be created, and they have been checked already
     * Key here is that destination_understandings is created in the same order as destinations
     * This means that we can use unnest on both arrays to link the destination children array with the destination understanding
     * The trick is then working out how to run update_children on them
    */

    
    EXECUTE format(
        'WITH inserted AS (
            INSERT INTO @extschema@.%I (name, author, year, parent)
            SELECT t.name, $3, $4, destination_parent FROM (
                SELECT unnest((a).children) source_child, b destination_parent FROM (
                    SELECT unnest($1) as a,
                    unnest($2) as b
                ) as x
            ) as y
            JOIN @extschema@.%I t on source_child = t.id
            RETURNING id
        )
        SELECT array_agg(id) FROM inserted;',
        child_level.name, child_level.name
    )
    USING destinations, destination_understandings, author, year
    INTO created_children;

    -- Next, make the composition for all that we just created
    EXECUTE FORMAT(
        'INSERT INTO @extschema@.%I_composition (subject, component)
        SELECT unnest($1), unnest($1)',
        child_level.name
    )
    USING created_children;

    -- Now we need to point the old understandings to their new ones
    -- Start by doing a select that gets the old understanding and the new one
    -- Then loop over that select and update the source current to be that of the destination
    FOR understanding IN
        select @extschema@.extract_split_ids(destinations) as source,unnest(created_children) as destination
    LOOP
        EXECUTE format(
            'UPDATE @extschema@.%I
            SET current = $2 WHERE id = $1',
            child_level.name
        )
        USING understanding.source, understanding.destination;
    END LOOP;
    
    /*
     * Children are now created in the same order that extracting the children from destinations are
     * This means it is possible to run update_children using the table of results
    */

    -- First, check if there's a grandchild level. If there isn't, exit, job done!
    IF (@extschema@.select_child_level(child_level.id) IS NULL) THEN
        RETURN;
    END IF;

    -- There's a grandchild level, so we're not quite done yet
    -- We can use the same loop as before to push into update_children though, so it's fast

    FOR understanding IN
        select @extschema@.extract_split_ids(destinations) as source,unnest(created_children) as destination
    LOOP
        CALL @extschema@.update_children(child_level.id, understanding.source, understanding.destination);
    END LOOP;

    -- Now we should be done!
    

END;
$BODY$;