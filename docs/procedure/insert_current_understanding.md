# insert_current_understanding

## Signature
    insert_current_understanding(
        IN level_id INT,
        IN parent_id INT,
        IN name TEXT,
        IN author TEXT,
        IN year INT
    )

## Arguments

| Name      | Type | Description                                                                                                                                                                             |
| --------- | ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| level_id  | int  | The id of the level at which to insert a new understanding                                                                                                                              |
| parent_id | int  | The id of the parent understanding on the parent level                                                                                                                                  |
| name      | text | The name of the new understanding. Note that this can contain 'agg' or 'complex', though it is recommended to use the `split_understanding` procedure to split a current understanding. |
| author    | text | The author of the understanding                                                                                                                                                         |
| year      | int  | The year of the understanding                                                                                                                                                           |

## Explanation
Call this to create a new, currently valid, understanding.

The code is just a wrapper around the function `create_understanding`, designed to standardise NoNomS actions as procedures rather than a mixture of functions and procedures. Also removes the need for the user to understand what a `NULL` is and how to use them.

## Example