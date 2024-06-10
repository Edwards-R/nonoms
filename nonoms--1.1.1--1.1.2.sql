CREATE OR REPLACE PROCEDURE insert_rank(
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
$BODY$;