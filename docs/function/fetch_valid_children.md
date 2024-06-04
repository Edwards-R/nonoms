# extract_split_ids

## Signature
    fetch_valid_children(
        level_id integer,
        target_understanding integer
    )
    RETURNS TABLE(
        id integer, name text
    )

## Arguments
| Name                 | Type | Description                                                |
| -------------------- | ---- | ---------------------------------------------------------- |
| level_id             | int  | The id of the level that the parent                        |
| target_understanding | int  | The id of the understanding to fetch the valid children of |

## Returns
A table of all the valid i.e. non-synonym or aggregate children of the provided target

## Explanation
Finds all the valid i.e. non-synonym or aggregate children of the provided target

## Example