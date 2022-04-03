\set schema sample
select rt.tbls_regular as tbls_regular, ut.unlogged_tables as tbls_unlogged, pt.partitions as tbls_child, pn.parents as tbls_parents, rt.tbls_regular + ut.unlogged_tables + pt.partitions + pn.parents as tbls_total, se.sequences as sequences, ide.identities as identities, ix.indexes as indexes, vi.views as views, pv.pviews as pub_views, mv.mats as mat_views, fn.functions as functions, ty.types as types, tf.trigfuncs, tr.triggers as triggers, co.collations as collations, dom.domains as domains, ru.rules as rules, po.policies as policies, com.comments as comments from (select count(*) as tbls_regular FROM pg_class c, pg_tables t, pg_namespace n where t.schemaname = :'schema' and t.tablename = c.relname and c.relkind = 'r' and n.oid = c.relnamespace and n.nspname = t.schemaname and c.relpersistence = 'p' and c.relispartition is false) rt, (select count(distinct (t.schemaname, t.tablename)) as unlogged_tables from pg_tables t, pg_class c where t.schemaname = :'schema' and t.tablename = c.relname and c.relkind = 'r' and c.relpersistence = 'u' ) ut, (SELECT count(*) as sequences FROM pg_class c, pg_namespace n where n.oid = c.relnamespace and c.relkind = 'S' and n.nspname = :'schema') se, (SELECT count(*) as identities FROM pg_sequences where schemaname = :'schema' AND NOT EXISTS (select 1 from information_schema.sequences where sequence_schema = :'schema' and sequence_name = sequencename)) ide, (select count(*) as indexes from pg_class c, pg_namespace n, pg_indexes i where n.nspname = :'schema' and n.oid = c.relnamespace and c.relkind <> 'p' and n.nspname = i.schemaname and c.relname = i.tablename) ix, (select count(*) as views from pg_views where schemaname = :'schema') vi, (select count(*) as pviews from pg_views where schemaname = 'public') pv, (SELECT count(distinct i.inhparent) as parents from pg_inherits i, pg_class c, pg_namespace n  where c.relkind in ('p','r') and i.inhparent = c.oid and c.relnamespace = n.oid and n.nspname = :'schema') pn, (SELECT count(*) as partitions FROM pg_inherits JOIN pg_class AS c ON (inhrelid=c.oid) JOIN pg_class as p ON (inhparent=p.oid) JOIN pg_namespace pn ON pn.oid = p.relnamespace JOIN pg_namespace cn ON cn.oid = c.relnamespace WHERE pn.nspname = :'schema' and c.relkind = 'r') pt, (SELECT count(*) as functions FROM pg_proc p INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid) WHERE ns.nspname = :'schema') fn, (SELECT count(*) as types FROM pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid) AND n.nspname = :'schema') ty, (SELECT count(*) as trigfuncs FROM pg_catalog.pg_proc p LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang WHERE pg_catalog.pg_get_function_result(p.oid) = 'trigger' and n.nspname = :'schema') tf, (SELECT count(distinct (trigger_schema, trigger_name, event_object_table, action_statement, action_orientation, action_timing)) as triggers  FROM information_schema.triggers WHERE trigger_schema = :'schema') tr, (select count(distinct(n.nspname, c.relname)) as mats from pg_class c, pg_namespace n where c.relnamespace = n.oid and c.relkind = 'm') mv, (SELECT count(*) as collations FROM pg_collation c JOIN pg_namespace n ON (c.collnamespace = n.oid) JOIN pg_authid a ON (c.collowner = a.oid) WHERE n.nspname = :'schema') co, (SELECT count(*) as domains FROM pg_catalog.pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE t.typtype = 'd' AND n.nspname OPERATOR(pg_catalog.~) '^(sample)$' COLLATE pg_catalog.default) dom, (select count(*) as rules from pg_rules where schemaname = :'schema') ru, (select count(*) as policies from pg_policies where schemaname = :'schema') po,(select sum(cnts.cnt) as comments FROM (SELECT count(*) as cnt FROM pg_class c JOIN pg_namespace n ON (n.oid = c.relnamespace) LEFT JOIN pg_description d ON (c.oid = d.objoid) LEFT JOIN pg_attribute a ON (c.oid = a.attrelid AND a.attnum > 0 and a.attnum = d.objsubid) WHERE d.description IS NOT NULL AND n.nspname = 'sample' UNION ALL SELECT count(*) as cnt from pg_namespace n, pg_description d where d.objoid = n.oid and n.nspname = 'sample' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid) AND n.nspname = 'sample' COLLATE pg_catalog.default AND pg_catalog.obj_description(t.oid, 'pg_type') IS NOT NULL and t.typtype = 'c' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_collation c, pg_catalog.pg_namespace n WHERE n.oid = c.collnamespace AND c.collencoding IN (-1, pg_catalog.pg_char_to_encoding(pg_catalog.getdatabaseencoding())) AND n.nspname OPERATOR(pg_catalog.~) '^(sample)$' COLLATE pg_catalog.default AND pg_catalog.obj_description(c.oid, 'pg_collation') IS NOT NULL UNION ALL SELECT count(*) as cnt from pg_catalog.pg_namespace n JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid JOIN pg_description d ON (d.objoid = p.oid) WHERE n.nspname = 'sample' UNION ALL SELECT count(*) as cnt from pg_policies p1, pg_policy p2, pg_class c, pg_namespace n, pg_description d WHERE p1.schemaname = n.nspname and p1.tablename = c.relname and n.oid = c.relnamespace and c.relkind in ('r','p') and p1.policyname = p2.polname and d.objoid = p2.oid and p1.schemaname = 'sample' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace JOIN pg_catalog.pg_description d ON d.classoid = t.tableoid AND d.objoid = t.oid AND d.objsubid = 0 WHERE t.typtype = 'd' AND n.nspname = 'sample' COLLATE pg_catalog.default) cnts) com;
\set schema sample_clone
select rt.tbls_regular as tbls_regular, ut.unlogged_tables as tbls_unlogged, pt.partitions as tbls_child, pn.parents as tbls_parents, rt.tbls_regular + ut.unlogged_tables + pt.partitions + pn.parents as tbls_total, se.sequences as sequences, ide.identities as identities, ix.indexes as indexes, vi.views as views, pv.pviews as pub_views, mv.mats as mat_views, fn.functions as functions, ty.types as types, tf.trigfuncs, tr.triggers as triggers, co.collations as collations, dom.domains as domains, ru.rules as rules, po.policies as policies, com.comments as comments from (select count(*) as tbls_regular FROM pg_class c, pg_tables t, pg_namespace n where t.schemaname = :'schema' and t.tablename = c.relname and c.relkind = 'r' and n.oid = c.relnamespace and n.nspname = t.schemaname and c.relpersistence = 'p' and c.relispartition is false) rt, (select count(distinct (t.schemaname, t.tablename)) as unlogged_tables from pg_tables t, pg_class c where t.schemaname = :'schema' and t.tablename = c.relname and c.relkind = 'r' and c.relpersistence = 'u' ) ut, (SELECT count(*) as sequences FROM pg_class c, pg_namespace n where n.oid = c.relnamespace and c.relkind = 'S' and n.nspname = :'schema') se, (SELECT count(*) as identities FROM pg_sequences where schemaname = :'schema' AND NOT EXISTS (select 1 from information_schema.sequences where sequence_schema = :'schema' and sequence_name = sequencename)) ide, (select count(*) as indexes from pg_class c, pg_namespace n, pg_indexes i where n.nspname = :'schema' and n.oid = c.relnamespace and c.relkind <> 'p' and n.nspname = i.schemaname and c.relname = i.tablename) ix, (select count(*) as views from pg_views where schemaname = :'schema') vi, (select count(*) as pviews from pg_views where schemaname = 'public') pv, (SELECT count(distinct i.inhparent) as parents from pg_inherits i, pg_class c, pg_namespace n  where c.relkind in ('p','r') and i.inhparent = c.oid and c.relnamespace = n.oid and n.nspname = :'schema') pn, (SELECT count(*) as partitions FROM pg_inherits JOIN pg_class AS c ON (inhrelid=c.oid) JOIN pg_class as p ON (inhparent=p.oid) JOIN pg_namespace pn ON pn.oid = p.relnamespace JOIN pg_namespace cn ON cn.oid = c.relnamespace WHERE pn.nspname = :'schema' and c.relkind = 'r') pt, (SELECT count(*) as functions FROM pg_proc p INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid) WHERE ns.nspname = :'schema') fn, (SELECT count(*) as types FROM pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid) AND n.nspname = :'schema') ty, (SELECT count(*) as trigfuncs FROM pg_catalog.pg_proc p LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang WHERE pg_catalog.pg_get_function_result(p.oid) = 'trigger' and n.nspname = :'schema') tf, (SELECT count(distinct (trigger_schema, trigger_name, event_object_table, action_statement, action_orientation, action_timing)) as triggers  FROM information_schema.triggers WHERE trigger_schema = :'schema') tr, (select count(distinct(n.nspname, c.relname)) as mats from pg_class c, pg_namespace n where c.relnamespace = n.oid and c.relkind = 'm') mv, (SELECT count(*) as collations FROM pg_collation c JOIN pg_namespace n ON (c.collnamespace = n.oid) JOIN pg_authid a ON (c.collowner = a.oid) WHERE n.nspname = :'schema') co, (SELECT count(*) as domains FROM pg_catalog.pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE t.typtype = 'd' AND n.nspname OPERATOR(pg_catalog.~) '^(sample)$' COLLATE pg_catalog.default) dom, (select count(*) as rules from pg_rules where schemaname = :'schema') ru, (select count(*) as policies from pg_policies where schemaname = :'schema') po,(select sum(cnts.cnt) as comments FROM (SELECT count(*) as cnt FROM pg_class c JOIN pg_namespace n ON (n.oid = c.relnamespace) LEFT JOIN pg_description d ON (c.oid = d.objoid) LEFT JOIN pg_attribute a ON (c.oid = a.attrelid AND a.attnum > 0 and a.attnum = d.objsubid) WHERE d.description IS NOT NULL AND n.nspname = 'sample' UNION ALL SELECT count(*) as cnt from pg_namespace n, pg_description d where d.objoid = n.oid and n.nspname = 'sample' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid) AND n.nspname = 'sample' COLLATE pg_catalog.default AND pg_catalog.obj_description(t.oid, 'pg_type') IS NOT NULL and t.typtype = 'c' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_collation c, pg_catalog.pg_namespace n WHERE n.oid = c.collnamespace AND c.collencoding IN (-1, pg_catalog.pg_char_to_encoding(pg_catalog.getdatabaseencoding())) AND n.nspname OPERATOR(pg_catalog.~) '^(sample)$' COLLATE pg_catalog.default AND pg_catalog.obj_description(c.oid, 'pg_collation') IS NOT NULL UNION ALL SELECT count(*) as cnt from pg_catalog.pg_namespace n JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid JOIN pg_description d ON (d.objoid = p.oid) WHERE n.nspname = 'sample' UNION ALL SELECT count(*) as cnt from pg_policies p1, pg_policy p2, pg_class c, pg_namespace n, pg_description d WHERE p1.schemaname = n.nspname and p1.tablename = c.relname and n.oid = c.relnamespace and c.relkind in ('r','p') and p1.policyname = p2.polname and d.objoid = p2.oid and p1.schemaname = 'sample' UNION ALL SELECT count(*) as cnt FROM pg_catalog.pg_type t LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace JOIN pg_catalog.pg_description d ON d.classoid = t.tableoid AND d.objoid = t.oid AND d.objsubid = 0 WHERE t.typtype = 'd' AND n.nspname = 'sample' COLLATE pg_catalog.default) cnts) com;
-- check counts
select schemaname, relname, n_live_tup from pg_stat_user_tables where schemaname in ('sample','sample_clone') order by relname;
