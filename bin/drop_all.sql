CREATE OR REPLACE FUNCTION drop_all () 
   RETURNS VOID  AS
   $$
   DECLARE rec RECORD; 
   BEGIN
       -- Get all the schemas
        FOR rec IN
        select distinct schemaname
         from pg_catalog.pg_tables
         -- You can exclude the schema which you don't want to drop by adding another condition here
         where schemaname not like 'pg_catalog' and schemaname not like 'information_schema'
           LOOP
             EXECUTE 'DROP SCHEMA ' || rec.schemaname || ' CASCADE'; 
           END LOOP; 
           RETURN; 
   END;
   $$ LANGUAGE plpgsql;
 
select drop_all();

DROP FUNCTION drop_all();
