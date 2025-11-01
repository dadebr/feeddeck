-- Script para verificar o estado do database após a refatoração

-- 1. Verificar estrutura da tabela sources (não deve ter isFavorite, category, tags)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sources'
ORDER BY ordinal_position;

-- 2. Verificar estrutura da tabela items (deve ter category e tags)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'items'
ORDER BY ordinal_position;

-- 3. Verificar policies na tabela columns
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'columns';

-- 4. Verificar policies na tabela sources
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'sources';

-- 5. Verificar triggers na tabela sources
SELECT trigger_name, event_manipulation, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'sources';

-- 6. Verificar se há smart columns
SELECT id, name, "isSmartColumn", "smartFilter"
FROM columns
WHERE "isSmartColumn" = true;
