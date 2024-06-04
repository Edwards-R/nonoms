# as_understanding

## Signature
    as_understanding(
        name TEXT,
        author TEXT,
        year INT
    )
    RETURNS TEXT

## Arguments

| Name   | Description                             |
| ------ | --------------------------------------- |
| name   | The name of the Understanding to format |
| author | The author for the Understanding        |
| year   | The year of the Understanding           |

## Returns
A iso. formatted understanding in the form of `name`: iso. `author`: `year`

## Explanation
A standardised way to construct iso. formatted understandings.

Can be used on species, then prefixed by the genus, to create binomial understandings. 99% of how people interact with NoNomS will be via binomial understandings.

## Example
    SELECT nomenclature.as_understanding(name, author, year)
    FROM species

---
    SELECT g.name || ' ' || nomenclature.as_understanding(s.name, s.author, s.year) AS binomial_understanding
    FROM species s
    JOIN genus g on s.parent = g.id