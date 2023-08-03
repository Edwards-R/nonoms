CREATE OR REPLACE FUNCTION create_understanding(
        level_id integer,
        parent_id integer,
        name text,
        author text,
        year integer,
        current integer
    )
    RETURNS integer
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    -- Variables
    level RECORD;
    parent_level RECORD;
    parent RECORD;
    c INT;
BEGIN
    -- Code
    -- Fetch the level details
    level = @extschema@.select_level(level_id);

    -- Fetch the direct parent level details
    parent_level = @extschema@.select_parent_level(level_id);

    -- Prevent trying to create a new capstone
    IF parent_level.id = level.id THEN
        RAISE EXCEPTION 'Cannot create a new capstone - If exobiology has indeed been discovered, the author wants to know (and it would still be wrong to do this)';
    END IF;

    -- Fetch the parent
    EXECUTE format(
        'SELECT * FROM @extschema@.%I WHERE id = $1',
        parent_level.name
    )
    INTO parent
    USING parent_id;

    -- Exit if the parent is a synonym and 'current' is not defined
    IF current IS NULL AND parent.id != parent.current THEN
        raise EXCEPTION 'Cannot create a current name under a synonym parent';
    END IF;

    -- The awkward part - handling the difference between null current and defined current
    -- If current is null, this is a new taxa. Current will be set by the on-insert triggers

    -- Could wrap this function into a 'create current' and 'create synonym' to avoid the poorly
    -- indicated 'null' requirement

    IF current IS NULL THEN
        EXECUTE format(
            'INSERT INTO @extschema@.%I (name, author, year, parent) VALUES($1, $2, $3, $4) RETURNING id',
            level.name
        )
        INTO c
        USING name, author, year, parent_id;
    ELSE
        EXECUTE format(
            'INSERT INTO @extschema@.%I (name, author, year, parent, current) VALUES($1, $2, $3, $4, $5) RETURNING id',
            level.name
        )
        INTO c
        USING name, author, year, parent_id, current;
    END IF;

    -- Add self as component
    EXECUTE format(
        'INSERT INTO @extschema@.%I_composition (subject, component) VALUES ($1, $1)',
        level.name
    )
    USING c;

    RETURN c;
END;
$BODY$;