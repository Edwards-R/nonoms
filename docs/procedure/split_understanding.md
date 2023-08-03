# split_understanding

## Signature
    split(
        IN level_id integer,
        IN source integer,
        IN author text,
        IN year integer,
        IN destinations @extschema@.split_result[]
    )

## Arguments
### level_id
The id of the level that this operation takes place at

### source
The id of the understanding to split

### author
The author of the split

### year
The year of the split

### destinations
The destinations of the split, as well as the assignment of where all the current children of the source end up

## Explanation
An all-in-one function to handle the splitting of an understanding into multiple.

## Example
    CALL nomenclature.split_understanding(
        2,
        2,
        'test_auth',
        2023,
        ARRAY[
            ('part_one'::text, '{4}'),
            ('part_two'::text, '{5}')
        ]::nomenclature.split_result[]
    )