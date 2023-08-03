# rank

## Explanation

This table stores all rank-related information. Primary, this is the name of the rank and what it considers as the parent rank.

The exception to this is the `capstone` rank, which represents the highest point in the hierarchy, saving the need to enter higher orders. Simply assume the capstone to be the higher common grouping required for your needs and work down from there.

The capstone rank can be identified by the fact that its `id` and `major_parent` are the same.

Rank has the option for 'minor' ranks to be added (NoNomS spec for a minor rank is one that does not participate in the main backbone), but this is inoperative at the moment and exists purely for manual queries. Unless comfortable with manual queries and general design, it is recommend to stick to using only major ranks.

## Data Dictionary
|Attribute|Type|Description|
|---------|----|------------
|id|int|Primary key, auto-increments|
|name|text|The name of the rank e.g. species, genus etc. This will be used to refer to the table in the schema and so should be all lower case. Must be unique, enforced by constraint|
major_parent|int|The id of the major rank that is considered the next node above this one on the rank backbone. Each rank may only be referenced *once* by this field, creating a linear relationship between ranks|
|direct_parent|int|The id of the rank, major or minor, that is considered the next node above this, regardless of the backbone. Not fully implemented yet, should be set to the same as the `major_parent`. Avoid modifying from this unless confident in relational design & queries.|
|display_name|text|The formatted, free-form text name for the rank. Restrictions, predominantly capitalisation, are removed here.|
|is_major|boolean|Is the rank major (`true`) or minor (`false`). Avoid setting to false unless comfortable with manual manipulation of SQL, as non-major ranks - i.e. minor - are not supported yet.