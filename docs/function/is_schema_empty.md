# is_schema_empty

## Signature
    is_schema_empty(
    )
    RETURNS BOOLEAN

## Arguments
*None*

## Returns
Yes if the schema is considered empty for the purpose of running the `init()` procedure

## Explanation
`init` is only designed to be called on empty schema. This function is where to put checks to try to prevent problems arising from `init`-ing in a populated schema. Not guaranteed to be fool-proof, it's still going to be best practice to start with a newly created schema for the extension's own use.

## Example