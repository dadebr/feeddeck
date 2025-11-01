-- Script de diagnóstico para investigar erros 500
-- Execute este script no SQL Editor do Supabase Dashboard

-- 1. Verificar se há colunas inesperadas em sources
SELECT 'Sources columns:' as info, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'sources'
ORDER BY ordinal_position;

-- 2. Verificar triggers em sources
SELECT 'Sources triggers:' as info, trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public' AND event_object_table = 'sources';

-- 3. Verificar policies em columns
SELECT 'Columns policies:' as info, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'columns';

-- 4. Verificar se há foreign keys problemáticas
SELECT 'Foreign keys:' as info,
       tc.table_name,
       kcu.column_name,
       ccu.table_name AS foreign_table_name,
       ccu.column_name AS foreign_column_name,
       rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('columns', 'sources', 'items');

-- 5. Tentar deletar uma coluna de teste (se houver)
-- CUIDADO: Isso vai deletar uma coluna real se você tiver uma com esse ID
-- Descomente apenas se tiver certeza:
-- DELETE FROM columns WHERE name = 'TEST_DELETE_ME';

-- 6. Verificar indexes órfãos
SELECT 'Indexes on sources:' as info, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'sources';
