# select_child_level

## Signature
    select_child_level(
	    level_id integer
    )
    RETURNS record

## Arguments

### level_id

The level id of the level to return the child of

## Returns

A record from the `levels` table

## Explanation

Used as a shorthand abstraction for querying the `levels` table to find the child of a given level. Returns `null` if the current level is the lowest.

## Example