# Run `make -B` to build, then `make install` to install

EXTENSION = nonoms
EXTVERSION = 1.1.4

# This looks for a target. If it can't find it, it makes it
DATA = $(EXTENSION)--$(EXTVERSION).sql

# This is a target
$(EXTENSION)--$(EXTVERSION).sql: \
	type/*.sql \
	function/*.sql \
	procedure/*.sql \
	trigger/*.sql
		cat $^ > $@

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)