# make_aggregate

## Signature
    make_aggregate(
        level_id integer,
        source_id integer,
        author text,
        year integer
    )
    RETURNS integer

## Arguments

### level_id
The id of the level that this function is operating at

### source_id
The target understanding to have an aggregate understanding made of them

### author
The author's name for the aggregate understanding

### year
The year of publiction of the aggregate understanding

## Returns
The id of the newly created understanding

## Explanation
A function which abstracts the creation of an aggregate understanding. Note that this does not also fill in the components of that aggregate by itself and that this function should not be called directly. Instead, use the `split` procedure.

## Example