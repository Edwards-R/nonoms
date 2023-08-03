CREATE OR REPLACE FUNCTION create_multiple_current_understandings(
        level_id integer,
        parent_id integer,
        name text[],
        author text,
        year integer
    )
    RETURNS integer[]
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    -- Variables
    level RECORD;
    parent_level RECORD;
    parent RECORD;
    c INT[];
BEGIN
    -- Fetch the level details
    level = @extschema@.select_level(level_id);

    -- Fetch the parent level details
    parent_level = @extschema@.select_parent_level(level_id);

    -- Fetch the parent
    EXECUTE format(
        'SELECT * FROM @extschema@.%I WHERE id = $1',
        parent_level.name
    )
    INTO parent
    USING parent_id;

    -- Exit if the parent is a synonym
    IF parent.id != parent.current THEN
        raise EXCEPTION 'Cannot create a current name under a synonym parent';
    END IF;

    -- Insert the data
    EXECUTE format(
        'CREATE TEMPORARY TABLE rot_multi_create AS 
            WITH i AS (
                INSERT into @extschema@.%I (
                name,
                author,
                year,
                parent
            )
            SELECT *, $2, $3, $4
            FROM UNNEST($1)
            returning id
        )
        select * from i;
        
        insert into @extschema@.%I_composition (subject, component) select rot_multi_create.*, rot_multi_create.* from rot_multi_create;',
        level.name, level.name
    )
    USING name, author, year, parent_id;

    -- Move the temporary table into an array so that it can transmitted without leaving a table open
    SELECT array_agg(id) FROM rot_multi_create INTO c;

    -- Delete the table
    drop table rot_multi_create;

    -- Return the array
    return c;
END;
$BODY$;