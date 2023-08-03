-- Designed to run in a freshly created schema
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
$BODY$;