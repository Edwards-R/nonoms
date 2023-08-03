# update_children

## Signature
    update_children(
        IN level_id integer,
        IN input integer,
        IN output integer
    )

## Arguments

### level_id
The id of the level that this operation takes place at

### input
The id of the source understanding to select all children of

### output
The id of the destination understanding to update (NoNomS term update, not SQL `update`) the children of the input to

## Explanation
When an understanding is changed, it sets the old to synonym status. According to NoNomS rules, all currently valid children of a changed understanding must be re-created under the new understanding. This function handles doing this via recursion. Simply provide it with the 'top level' id, input, and output from a split/merge children (*not* the merge itself) and the function handles the rest. Do not use by itself! `split` and `merge` have this baked in and should be used instead.

## Example