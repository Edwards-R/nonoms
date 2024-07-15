CREATE TYPE split_result AS
(
	name text,
	children integer[]
);CREATE OR REPLACE FUNCTION as_understanding(
        name TEXT,
        author TEXT,
        year INT
    )
    RETURNS TEXT
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
   
BEGIN
    RETURN name || ': iso. ' || author || ': ' || year;
END;
$BODY$;CREATE OR REPLACE FUNCTION create_multiple_current_understandings(
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
$BODY$;CREATE OR REPLACE FUNCTION create_understanding(
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
$BODY$;CREATE OR REPLACE FUNCTION extract_split_ids(
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
$BODY$;CREATE OR REPLACE FUNCTION fetch_valid_children(
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
$BODY$;CREATE OR REPLACE FUNCTION is_schema_empty(
    )
    RETURNS BOOLEAN
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    num_tables INT;
BEGIN
    num_tables=0;
    SELECT count(*) FROM information_schema.tables 
    WHERE table_schema = '@extschema@' INTO num_tables;

    IF num_tables>0 THEN
        return FALSE;
    END IF;

    -- Finally, all checks passed
    RETURN TRUE;
END;
$BODY$;CREATE OR REPLACE FUNCTION make_aggregate(
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
$BODY$;CREATE OR REPLACE FUNCTION select_child_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT * FROM @extschema@.rank WHERE major_parent = level_id AND id!=major_parent INTO result;
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;
CREATE OR REPLACE FUNCTION select_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT * FROM @extschema@.rank WHERE id = level_id INTO result;
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;CREATE OR REPLACE FUNCTION select_parent_level(
	    level_id integer
    )
    RETURNS record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    result RECORD;
BEGIN
    SELECT t2.*
    FROM @extschema@.rank t
    JOIN @extschema@.rank t2 on t.major_parent = t2.id
    WHERE t.id = level_id
    INTO result;
    
    IF result.id IS NULL THEN
        result = null;
    END IF;
    RETURN result;
END;
$BODY$;-- This script checks to see if a given split is possible to perform
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
$BODY$;-- This procedure assumes the existence of 'genus' and 'species' rank tables. It *WILL NOT WORK* without them
CREATE OR REPLACE PROCEDURE create_binomial_view()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    presence_check INT;
BEGIN
    -- Check to see if species and genus are present

    SELECT COUNT(*) FROM @extschema@.rank WHERE name = 'genus' INTO presence_check;

    IF presence_check != 1 THEN
        RAISE EXCEPTION 'Genus table not found/not unique';
    END IF;

    SELECT COUNT(*) FROM @extschema@.rank WHERE name = 'species' INTO presence_check;
    
    IF presence_check != 1 THEN
        RAISE EXCEPTION 'Species table not found/not unique';
    END IF;

    -- Tables are both present, not my problem now if they're malformed!
    CREATE VIEW @extschema@.binomial AS (
        SELECT s.id, s.current, g.name || ' ' || @extschema@.as_understanding(s.name, s.author, s.year) binomial
        FROM @extschema@.species s
        JOIN @extschema@.genus g on s.parent = g.id
    );

END;
$BODY$;CREATE OR REPLACE PROCEDURE create_rank_table(
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE

BEGIN
CREATE TABLE IF NOT EXISTS @extschema@.rank
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    name text COLLATE pg_catalog."default" NOT NULL,
    major_parent integer NOT NULL,
    direct_parent integer NOT NULL,
    display_name text COLLATE pg_catalog."default" NOT NULL,
    is_major boolean NOT NULL,
    CONSTRAINT rank_pkey PRIMARY KEY (id),
    CONSTRAINT rank_name_key UNIQUE (name),
    CONSTRAINT direct_parent FOREIGN KEY (direct_parent)
        REFERENCES @extschema@.rank (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT major_parent FOREIGN KEY (major_parent)
        REFERENCES @extschema@.rank (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE INITIALLY DEFERRED
);
END;
$BODY$;-- Designed to run in a freshly created schema
CREATE OR REPLACE PROCEDURE init_nonoms(
        IN scheme_name TEXT,
        IN scheme_year INT,
        IN override BOOLEAN DEFAULT FALSE
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    empty_check BOOLEAN;
    num_tables INT;
BEGIN
    -- Is the destination schema empty?
    SELECT @extschema@.is_schema_empty() INTO empty_check;

    IF empty_check = FALSE AND override = FALSE THEN
        RAISE EXCEPTION 'Attempting to initialise NoNomS in an already populated schema. This is highly advised against, check that you meant to do this. If you did, use init_nonoms(true) to override this warning';
        RETURN;
    END IF;

    -- Create the rank table
    CALL @extschema@.create_rank_table();

    -- Populate it with the capstone rank
    CALL @extschema@.insert_rank('capstone', 1, 'Capstone', TRUE);

    -- Create the capstone
    INSERT INTO @extschema@.capstone(name, author, year, parent, current) VALUES ('Capstone', scheme_name, scheme_year, 1, 1);

    -- Create the capstone composition
    INSERT INTO @extschema@.capstone_composition(subject, component) VALUES (1,1);
END;
$BODY$;-- Just a wrapper around the function to bring creation in line with merge/split
-- Also used to make a clean distinction between creating as current or synonym without the user needing to understand what a NULL is
CREATE OR REPLACE PROCEDURE insert_current_understanding(
        IN level_id INT,
        IN parent_id INT,
        IN name TEXT,
        IN author TEXT,
        IN year INT
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    
BEGIN
    PERFORM @extschema@.create_understanding(level_id, parent_id, name, author, year, NULL); 
END;
$BODY$;CREATE OR REPLACE PROCEDURE insert_rank(
        IN rank_name TEXT,
        IN rank_parent INT,
        IN display_name TEXT,
        IN capstone_override BOOLEAN DEFAULT FALSE
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    parent_rank_name TEXT;
    -- ID of the created rank, used to avoid fetching capstone
    created_rank_id INT;
BEGIN

-- Insert the entry into the rank table
INSERT INTO @extschema@.rank (
    name,
    major_parent,
    direct_parent,
    display_name,
    is_major
) VALUES (
    rank_name,
    rank_parent,
    rank_parent,
    display_name,
    true
) RETURNING id INTO created_rank_id;

-- Create the table

-- Need to label the constraint with the parent's name
-- Query ensures that capstone is never selected unless specifically overriden
IF capstone_override != TRUE THEN
    SELECT name
    FROM @extschema@.rank
    WHERE id = rank_parent
    AND created_rank_id != major_parent
    INTO parent_rank_name;
ELSE
    SELECT name
    FROM @extschema@.rank
    WHERE id = rank_parent
    INTO parent_rank_name;
END IF;

-- Make the table for the rank
EXECUTE
    format(
        'CREATE TABLE IF NOT EXISTS @extschema@.%I
        (
            id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
            name text COLLATE pg_catalog."default" NOT NULL,
            author text COLLATE pg_catalog."default" NOT NULL,
            year integer NOT NULL,
            parent integer NOT NULL,
            current integer NOT NULL,
            CONSTRAINT %I_pkey PRIMARY KEY (id),
            CONSTRAINT %I_composite UNIQUE (name, author, year, parent),
            CONSTRAINT current FOREIGN KEY (current)
                REFERENCES @extschema@.%I (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                DEFERRABLE INITIALLY DEFERRED,
            CONSTRAINT parent FOREIGN KEY (parent)
                REFERENCES @extschema@.%I (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
        )',
        rank_name,
        rank_name,
        rank_name,
        rank_name,
        parent_rank_name
    )
;

-- Add the required trigger to auto-fill 'current' when the insert is non-synonym
EXECUTE
    format(
        'CREATE TRIGGER on_insert_understanding
        BEFORE INSERT
        ON @extschema@.%I
        FOR EACH ROW
        EXECUTE FUNCTION @extschema@.on_insert_understanding();',
        rank_name
    )
;

-- Make the composition table for the rank
EXECUTE
    format('
        CREATE TABLE IF NOT EXISTS @extschema@.%I_composition
        (
            id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
            subject integer NOT NULL,
            component integer NOT NULL,
            CONSTRAINT %I_composition_pkey PRIMARY KEY (id),
            CONSTRAINT component FOREIGN KEY (component)
                REFERENCES @extschema@.%I (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                DEFERRABLE INITIALLY DEFERRED,
            CONSTRAINT subject FOREIGN KEY (subject)
                REFERENCES @extschema@.%I (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                DEFERRABLE INITIALLY DEFERRED
        )
        ',
        rank_name,
        rank_name,
        rank_name,
        rank_name
    )
;

-- Add indexes
EXECUTE
    format('
        CREATE INDEX ON @extschema@.%I(id);
        CREATE INDEX ON @extschema@.%I(parent);
        CREATE INDEX ON @extschema@.%I_composition(subject);
        CREATE INDEX ON @extschema@.%I_composition(component);
        ',
        rank_name,
        rank_name,
        rank_name,
        rank_name
    )
;

END;
$BODY$;-- Just a wrapper around the function to bring creation in line with merge/split
-- Also used to make a clean distinction between creating as current or synonym without the user needing to understand what a NULL is
CREATE OR REPLACE PROCEDURE insert_synonym_understanding(
        IN level_id INT,
        IN parent_id INT,
        IN name TEXT,
        IN author TEXT,
        IN year INT,
        IN current INT
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    
BEGIN
    PERFORM @extschema@.create_understanding(level_id, parent_id, name, author, year, current); 
END;
$BODY$;CREATE OR REPLACE PROCEDURE merge_understandings(
        IN level_id integer,
        IN inputs integer[],
        IN name text,
        IN author text,
        IN year integer
    )
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
	level RECORD;
	parent INT;
	c INT;
	_elem INT; -- Used in for loop
BEGIN

-- Start by fetching the name of the rank
level = @extschema@.select_level(level_id);

-- Check that the inputs have the same parent
EXECUTE
	format(
		'SELECT COUNT(distinct(parent)) FROM @extschema@.%I WHERE id = ANY ($1)',
		level.name
	)
	into c
	USING inputs
;

IF (c !=1) THEN
	RAISE EXCEPTION 'Inputs must belong to the same parent taxon';
END IF;

-- Level exists, now check that all inputs are current and not synonyms
EXECUTE
	format('SELECT COUNT(*) FROM @extschema@.%I WHERE id != current AND id = ANY ($1)', level.name)
	INTO c
	USING inputs
;

-- If there's a synonym, stop
IF (c > 0) THEN
	RAISE EXCEPTION 'Inputs may not contain synonyms';
END IF;

-- Pre-checks completed, make the new entity and store the id in c

-- Start by fetching the parent
EXECUTE format('SELECT DISTINCT(parent) FROM @extschema@.%I WHERE id = ANY ($1)', level.name)
INTO parent
USING inputs;

-- Now create
SELECT @extschema@.create_understanding(level_id, parent, name, author, year, null) INTO c;

-- Update the old to redirect to the new
EXECUTE
	format('UPDATE @extschema@.%I SET current = $1 WHERE current = ANY ($2)', level.name)
	USING c, inputs
;

-- Push the current children of the inputs into the new taxa

FOREACH _elem IN ARRAY inputs
LOOP 
   	CALL @extschema@.update_children(level_id, _elem, c);
END LOOP;

END;
$BODY$;CREATE OR REPLACE PROCEDURE split_understanding(
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

    -- There's a granchild level, so we're not quite done yet
    -- We can use the same loop as before to push into update_children though, so it's fast

    FOR understanding IN
        select @extschema@.extract_split_ids(destinations) as source,unnest(created_children) as destination
    LOOP
        CALL @extschema@.update_children(child_level.id, understanding.source, understanding.destination);
    END LOOP;

    -- Now we should be done!
    

END;
$BODY$;CREATE OR REPLACE PROCEDURE update_children(
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
$BODY$;-- This wont work as it doesn't know where to assign it
CREATE OR REPLACE FUNCTION on_insert_understanding()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
	BEGIN
		IF NEW.current IS NULL THEN
			NEW.current = NEW.id;
		END IF;
		RETURN NEW;
END
$BODY$;