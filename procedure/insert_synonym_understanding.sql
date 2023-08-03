-- Just a wrapper around the function to bring creation in line with merge/split
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
$BODY$;