# split_child_check

## Signature
    split_child_check(
        level_id integer,
        source integer,
        destinations split_result[]
    )
    RETURNS boolean

## Arguments

### level_id

The id of the level that the split happens on

### source

The id of the source of the split

### destinations

An array of split_result objects representing the distribution of the children of the source

## Returns

A boolean value. True means that the check is passed, False means that the check failed

## Explanation

Checks to see if all children of the source are present in the destinations, and that no child is presented twice in the destinations

## Example