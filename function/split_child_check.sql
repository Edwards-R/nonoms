-- This script checks to see if a given split is possible to perform
-- It checks to see if all children of the parent are in the outputs,
-- and that outputs don't occur twice

CREATE OR REPLACE FUNCTION split_child_check(
        level_id integer,
        source integer,
        destinations @extschema@.split_result[]
    )
    RETURNS boolean
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    -- Variables
    c INT;
BEGIN
    -- Fetch the number of destinations which appear more than once
    SELECT count(cnt) from (
        SELECT COUNT(*) cnt FROM (
            SELECT * FROM @extschema@.extract_split_ids(destinations)
        ) as z
        GROUP BY id
    ) as a
    WHERE cnt > 1
    INTO c;

    -- Can't be having that
    IF c > 0 THEN
        RAISE NOTICE 'Destination appears more than once';
        RETURN FALSE;
    END IF;
    
    -- Check if all provided destinations are valid children of the source
    SELECT COUNT(*) FROM (
        SELECT id FROM @extschema@.extract_split_ids(destinations)
        WHERE id NOT IN (
            SELECT id FROM @extschema@.fetch_valid_children(level_id, source)
        )
    ) AS x
    INTO c;

    IF c > 0 THEN
        RAISE NOTICE 'There is a destination that is not a valid child of the source';
        RETURN FALSE;
    END IF;

    -- Check if all valid children of the source and present in the provided destinations
    SELECT COUNT(*) FROM (
        SELECT id FROM @extschema@.fetch_valid_children(level_id, source)
        WHERE id NOT IN (
            SELECT id FROM @extschema@.extract_split_ids(destinations)
        )
    ) AS x
    INTO c;

    IF c > 0 THEN
        RAISE NOTICE 'There is a valid child of the source which is not present in the provided destinations';
        RETURN FALSE;
    END IF;
    
    -- The end is reached, it passes!
    RETURN TRUE;
END;
$BODY$;