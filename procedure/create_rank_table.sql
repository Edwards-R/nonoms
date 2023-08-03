CREATE OR REPLACE PROCEDURE create_rank_table(
    )
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE

BEGIN
CREATE TABLE IF NOT EXISTS @extschema@.rank
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    name text COLLATE pg_catalog."default" NOT NULL,
    major_parent integer NOT NULL,
    direct_parent integer NOT NULL,
    display_name text COLLATE pg_catalog."default" NOT NULL,
    is_major boolean NOT NULL,
    CONSTRAINT rank_pkey PRIMARY KEY (id),
    CONSTRAINT rank_name_key UNIQUE (name),
    CONSTRAINT direct_parent FOREIGN KEY (direct_parent)
        REFERENCES @extschema@.rank (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT major_parent FOREIGN KEY (major_parent)
        REFERENCES @extschema@.rank (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        DEFERRABLE INITIALLY DEFERRED
);
END;
$BODY$;