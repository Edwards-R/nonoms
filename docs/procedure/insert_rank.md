# insert_rank

## Signature
    insert_rank(
        IN rank_name TEXT,
        IN rank_parent INT,
        IN display_name TEXT,
        IN capstone_override BOOLEAN DEFAULT FALSE
    )

## Arguments

### rank_name
The name of the rank. Must be:
- all lowercase
- no numbers
- no special characters
- no accented characters

### rank_parent
The ID of the rank that is above this one

### display_name
The name to display as text when this rank is referenced by the system. Not restricted by the system.

### capstone_override
There's a specific function in this function to prevent the creation of a capstone. However, we need to create a capstone rank on init. Flagging this variable as TRUE will bypass the check and allow capstone creation without needing replicate functions.

## Explanation
**Important! Read first!**

- Ranks must be created sequentially, from capstone downwards.
- There is no support for inserting ranks in the middle of others
- There is no support for adding new ranks once ranks have started to be populated (though it can be done manually *at great effort*)

It is ***highly*** recommended to start by establishing the rank structure first, then moving on to populating that rank structure.

***Do not ever set capstone_override to true unless developing***

## Example