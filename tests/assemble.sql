-- Delete the schema if it's there
DROP SCHEMA IF EXISTS nomenclature CASCADE;

-- Create it and load the extension into it
CREATE SCHEMA nomenclature;
CREATE EXTENSION nonoms WITH SCHEMA nomenclature;

-- Run the init procedure
CALL nomenclature.init_nonoms('BWARS', 2023);

-- Add in some test ranks
CALL nomenclature.insert_rank('family', 1, 'Family');
CALL nomenclature.insert_rank('genus', 2, 'Genus');
CALL nomenclature.insert_rank('species', 3, 'Species');

-- Add in some test entries

-- Family
CALL nomenclature.insert_current_understanding(2, 1, 'Vespidae', 'BWARS', 2000);
CALL nomenclature.insert_current_understanding(2, 1, 'Tiphiidae', 'BWARS', 2000);

-- Genus
CALL nomenclature.insert_current_understanding(3, 1, 'Vespula', 'BWARS', 2000);
CALL nomenclature.insert_current_understanding(3, 1, 'Polistes', 'BWARS', 2000);
CALL nomenclature.insert_current_understanding(3, 1, 'Eumenes', 'BWARS', 2000);

CALL nomenclature.insert_current_understanding(3, 2, 'Tiphia', 'BWARS', 2000);
CALL nomenclature.insert_current_understanding(3, 2, 'Methocha', 'BWARS', 2000);

-- Species
CALL nomenclature.insert_current_understanding(4, 1, 'vulgaris', 'Archer', 1989);
CALL nomenclature.insert_current_understanding(4, 1, 'rufa', 'Archer', 1989);
CALL nomenclature.insert_current_understanding(4, 1, 'germanica', 'Archer', 1989);
CALL nomenclature.insert_current_understanding(4, 1, 'austriaca', 'Archer', 1989);

CALL nomenclature.insert_current_understanding(4, 4, 'minuta', 'Richards', 1980);
CALL nomenclature.insert_current_understanding(4, 4, 'femorata', 'Richards', 1980);

-- Synonym
CALL nomenclature.insert_synonym_understanding(4, 4, 'wrongula', 'Richards', 1980, 6);