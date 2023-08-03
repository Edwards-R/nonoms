# Generic Rank Composition Table

## Explanation

This table stores what understandings make up any given understanding. For all non-aggregate entries, this will be only one entry. For aggregates (and complexes if being used), this will be every part of the aggregate but not the aggregate.

As an example, the 2008 Murray et al paper resulted in
- Bombus lucorum agg: iso. Murray et al: 2008
- Bombus lucorum: iso. Murray et al: 2008
- Bombus cryptarum: iso. Murray et al: 2008
- Bombus magnus: iso. Murray et al: 2008

The entries for lucorum, cryptarum, and magnus would all only reference themselves, while the entry for lucorum agg would reference lucorum, cryptarum, and magnus only. The aggregate understanding is ***not*** included.

If using the top-level procedures, this table is automatically filled out and nothing needs to be done to augment it.

## Data Dictionary
|Attribute|Type|Description|
|---------|----|-----------|
|id|int|Primary key
|subject|int|The primary key of the understanding that the composition is of|
|component|int|The primary key of the understanding that is a component of the subject|