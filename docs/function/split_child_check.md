# split_child_check

## Signature
    split_child_check(
        level_id integer,
        source integer,
        destinations split_result[]
    )
    RETURNS boolean

## Arguments
| Name        | Type           | Description                                                                                                                |
| ----------- | -------------- | -------------------------------------------------------------------------------------------------------------------------- |
| level_id    | int            | The id of the level that the split happens on                                                                              |
| source      | int            | The id of the source of the split                                                                                          |
| destination | split_result[] | An array of [split_result](/docs/type/split_result.md) objects representing the distribution of the children of the source |

## Returns
A boolean value. True means that the check is passed, False means that the check failed

## Explanation
Checks to see if all children of the source are present in the destinations, and that no child is presented twice in the destinations

## Example