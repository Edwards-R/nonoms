# To Do
THis document lists things that need to be done before any issue tracking gets involved, though once the project is built and running then these should get pushed to there

## Current Issues
- [ ] Make script that adds a rank, the rank table, and the rank understanding table
- [ ] Make a script that auto-creates the `capstone` table and then enters the capstone rank into it
- [ ] Make a view that produces binomial understandings
- [ ] Init procedure to set up the rank table
- [ ] Procedure to create new understanding
- [ ] Set all schema references to @extschema@
- [ ] Multiple ranks may have the same major parent - potential conflict with capstone could be the reason? Investigate

## Future Issues

- [ ] It is possible to enter capital letters and numbers into `rank.name`, which will break things. Add a trigger to enforce lower case alphabetic only.
- [ ] Minor ranks