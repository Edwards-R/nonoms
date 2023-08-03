# create_understanding

## Signature
    create_understanding(
        level_id integer,
        parent_id integer,
        name text,
        author text,
        year integer,
        current integer
    )
    RETURNS integer

## Arguments

### level_id
The id of the level to create the new understanding in

### parent_id
The id of the understanding that this new understanding should be created under

### name
The name of the new understanding

### author
The author of the new understanding

### year
The year of declaration of this new understanding

### current
A nullable integer. `null` means that the new understanding is current. A provided integer means that the new understanding is a synonym of an existing understanding.

## Returns
The id of the newly created understanding

## Explanation
The function to call to create a new understanding. Supplying `null` as the argument for `current` will create as a current understanding. Supplying an id will create the new understanding as a synonym of that id.

## Example