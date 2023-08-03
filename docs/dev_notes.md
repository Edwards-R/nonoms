# Dev Notes

## Dynamic extension schema
@extschema@ - would be non-relocatable after installation, which is expected. Set `relocatable = false` in the control file

## pg_dump
Anything data-wise created by the extension will NOT be exported by pg_dump. This means that no tables should be created in the SQL file, so instead make an `init` procedure that can be called post-install to set up whatever environment