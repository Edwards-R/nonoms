# select_parent_level

## Signature
    select_parent_level(
	    level_id integer
    )
    RETURNS record

## Arguments

### level_id

The level id of the level to return the parent of


## Returns
A record from the `levels` table

## Explanation
Used as a shorthand abstraction for querying the `levels` table to find the parent of a given level. Returns `null` if the current level is the highest.

## Example