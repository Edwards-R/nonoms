#on_insert_understanding

## Explanation

This trigger ensures that newly createad current understandings have their own `id` entered into the `current` attribute.

Since it's not possible to get the id of something at insert easily when using complex procedures & scripts, this trigger handles doing it at the point of insert.

Assigned to every created rank table