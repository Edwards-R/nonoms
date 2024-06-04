# create_multiple_current_understandings

## Signature
    create_multiple_current_understandings(
        level_id integer,
        parent_id integer,
        name text[],
        author text,
        year integer
    )
    RETURNS integer[]

## Arguments
| Name      | Type   | Description                                                                                           |
| --------- | ------ | ----------------------------------------------------------------------------------------------------- |
| level_id  | int    | The id of the level to create the new understanding in                                                |
| parent_id | int    | The id of the understanding that this new understanding should be created under                       |
| name      | text[] | The array of names of the new understandings                                                          |
| author    | text   | The author of the new understanding. This will be applied to all created understandings               |
| year      | int    | The year of declaration of this new understanding. This will be applied to all created understandings |

## Returns
The ids of the newly created understandings

## Explanation
The function to call to create multiple new current understandings. A shorthand optimisation to avoid multiple loops to create new understandings one-by-one when splitting a name.

## Example