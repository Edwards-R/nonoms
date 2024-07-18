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
    aggregate_id INT;
    temp_row RECORD; -- temporary variable used as iterator in FOR loops. Can't declare variables dynamically!
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
    CREATE TEMPORARY TABLE destination_table AS (
        WITH unnested AS (
            SELECT * FROM unnest(destinations)
        )

        SELECT @extschema@.create_understanding(
            level.id,
            subject.parent,
            name,
            author,
            year,
            NULL -- Current Understanding, so current = null
        ) as id, children
        FROM unnested
    );

    -- Create the aggregate
    aggregate_id = @extschema@.make_aggregate(level.id, subject.id, author, year);

    -- Assign the destination understandings as components of the aggregate
    EXECUTE format(
        'INSERT INTO nomenclature.%I_composition (subject, component) SELECT $1, id FROM destination_table',
        level.name
    )
    USING aggregate_id;

    -- Update the source to direct to the aggregate
    EXECUTE format(
        'UPDATE @extschema@.%I SET current = $2 WHERE current = $1',
        level.name
    ) USING source, aggregate_id;

    -- Now move on to working on the children of the destinations
    -- Exit if no child level
    IF child_level IS NULL THEN
        RETURN;
    END IF;

    /* 
     * There are children to be created, and they have been checked already
     * Key here is that destination_understandings is created in the same order as destinations
    */

    -- We have a table of the id of each destination, plus the ids of the children that belong in it
    -- Unnest that table to get a table of parent_id and details

    EXECUTE format('
        CREATE TEMPORARY TABLE children AS
        WITH destination_children AS (
            SELECT id as parent_id, UNNEST(children) child
            FROM destination_table
        ),

        new_children AS(
            SELECT child AS old_understanding, @extschema@.create_understanding(
                $3,
                parent_id,
                ns.name,
                $1,
                $2,
                NULL
            ) new_understanding
            FROM destination_children
            JOIN @extschema@.%I ns ON destination_children.child = ns.id
        ),

        update_command AS (
            UPDATE @extschema@.%I
            SET current = new_understanding
            FROM new_children
            WHERE current = old_understanding
        )

        SELECT old_understanding, new_understanding
        FROM new_children
    ', child_level.name, child_level.name)
    USING author, year, child_level.id;

    -- Modify the above query to output a table of the old_id and the new_id that can be passed to update_children (which is recursive)
    -- Run update_children?

    -- First, check if there's a grandchild level. If there isn't, exit, job done!
    IF (@extschema@.select_child_level(child_level.id) IS NULL) THEN
        RETURN;
    END IF;

    -- So there is a grandchild level. This means that we need to move valid grandchildren to the new
    -- update_children is recursive
    FOR temp_row IN
        SELECT old_understanding AS old_id, new_understanding AS new_id
        FROM children
    LOOP
        CALL @extschema@.update_children(child_level.id, temp_row.old_id, temp_row.new_id);
    END LOOP;
END;
$BODY$;