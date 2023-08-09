-- This procedure assumes the existence of 'genus' and 'species' rank tables. It *WILL NOT WORK* without them
CREATE OR REPLACE PROCEDURE create_binomial_view()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    presence_check INT;
BEGIN
    -- Check to see if species and genus are present

    SELECT COUNT(*) FROM @extschem@.rank WHERE name = "genus" INTO presence_check;

    IF presence_check != 1 THEN
        RAISE EXCEPTION('Genus table not found/not unique');
    END IF;

    SELECT COUNT(*) FROM @extschem@.rank WHERE name = "species" INTO presence_check;
    
    IF presence_check != 1 THEN
        RAISE EXCEPTION('Species table not found/not unique');
    END IF;

    -- Tables are both present, not my problem now if they're malformed!
    CREATE VIEW @extschema@.binomial AS (
        SELECT s.id, g.name || ' ' || @extschema@.as_understanding(s.name, s.author, s.year) binomial
        FROM @extschema@.species s
        JOIN @extschema@.genus g on s.parent = g.id
    )

END;
$BODY$;