# merge_understandings

## Signature
    merge_understandings(
        IN level_id integer,
        IN inputs integer[],
        IN name text,
        IN author text,
        IN year integer
    )

## Arguments
### level_id
The id of the level that this operation takes place at

### inputs
The id of the understandings to be merged

### name
The name of the new understanding to be created

### author
The author of the merge

### year
The year of the merge

## Explanation
An all-in-one function to handle merging multiple understandings into one.

## Example
    CALL nomenclature.merge_understandings(
        2,
        '{1,2}',
        'test_name',
        'test_auth',
        2023
    )