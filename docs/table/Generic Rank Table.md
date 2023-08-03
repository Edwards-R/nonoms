# *Generic Rank Table*

## Explanation

Each rank table is dynamically named, but will follow this convention. Simply put, this table contains the contents of each rank's entries - the understandings. Predominantly, their name and what they consider to be their parent understanding from the rank's parent's table of understandings.

## Data Dictionary
|Attribute|Type|Description|
|---------|----|-----------|
|id|int|The primary key for the understanding|
|name|text|The name of the understanding. Note that this *includes* the use of 'agg' for aggregates and *can* support 'complex', though use of complexes is not supported and will need to be managed manually.|
|author|text|The author of the understanding|
|year|int|The year of declaration of the understanding|
|parent|int|The id of the understanding in the parent rank's table that is considered the higher-order parent to this understanding. For example, the entry for 'humilis' in a 'species' table would reference the entry for 'Bombus' in the 'genus' table. This would result in 'Bombus humilis', with each entry having their respective understandings attached.|