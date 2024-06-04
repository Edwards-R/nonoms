# insert_rank

## Signature
    insert_rank(
        IN rank_name TEXT,
        IN rank_parent INT,
        IN display_name TEXT,
        IN capstone_override BOOLEAN DEFAULT FALSE
    )

## Arguments
| Name              | Type    | Description                                                                                                                                                                                             |
| ----------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| rank_name         | text    | The name of the rank. Must b, all lowercase,no numbers, no special characters, and no accented characters.                                                                                              |
| rank_parent       | int     | The ID of the rank that is above this one.                                                                                                                                                              |
| display_name      | text    | The name to display as text when this rank is referenced by the system. Not restricted by the system.                                                                                                   |
| capstone_override | boolean | A specific override to prevent the creation of a capstone entry. Only ever overriden when creating the capstone itself, all other uses will leave this as false. If in doubt at all, leave it as false. |

## Explanation
**Important! Read first!**

- Ranks must be created sequentially, from capstone downwards.
- There is no support for inserting ranks in the middle of others
- There is no support for adding new ranks once ranks have started to be populated (though it can be done manually *at great effort*)

It is ***highly*** recommended to start by establishing the rank structure first, then moving on to populating that rank structure.

***Do not ever set capstone_override to true unless developing***

## Example