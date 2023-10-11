# init_nonoms

## Signature
    init_nonoms(
        IN scheme_name TEXT,
        IN scheme_year INT,
        IN override BOOLEAN DEFAULT FALSE
    )

## Arguments

### scheme_name
The name of the scheme. Used to personalise/constraint the capstone so that multiple systems can talk to each other without conflict

## scheme_year
The# year of creation of the scheme. Used to personalise/constraint the capstone so that multiple systems can talk to each other without conflict

### override
Override creation warnings e.g. intialising inside of an already populated schema. Defaults to false.

## Explanation

Call this to initialise a new install of the NoNomS extension. Creates the `rank` table and populates it with `capstone`. Then creates the `capstone` and `capstone_composition` tables and populates them.

## Example