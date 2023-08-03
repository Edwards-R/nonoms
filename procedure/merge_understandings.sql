CREATE OR REPLACE PROCEDURE merge_understandings(
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
$BODY$;