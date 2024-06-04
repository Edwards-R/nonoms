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

| Name     | Type  | Description                                            |
| -------- | ----- | ------------------------------------------------------ |
| level_id | int   | The id of the level that this operation takes place at |
| inputs   | int[] | The ids of the understandings to be merged             |
| name     | text  | The name of the new understanding to be created        |
| author   | text  | The author of the merge                                |
| year     | int   | The year of the merge                                  |

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