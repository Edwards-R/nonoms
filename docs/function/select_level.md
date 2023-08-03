# select_level

## Signature
    select_level(
	    level_id integer
    )
    RETURNS record

## Arguments

### level_id
The level id of the level to return the details of

## Returns
A record from the `levels` table

## Explanation
Used as a shorthand abstraction for querying the `levels` table to find the details of a given level. Used to translate between level_ids and the name of that level in order to find the correct table to query.

## Example