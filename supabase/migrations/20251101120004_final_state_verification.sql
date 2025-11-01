------------------------------------------------------------------------------------------------------------------------
-- Final state verification and enforcement
-- This migration ensures the database is in the correct state after all refactoring
------------------------------------------------------------------------------------------------------------------------

-- SOURCES TABLE: Must NOT have isFavorite, category, tags
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check and drop isFavorite
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sources' AND column_name = 'isFavorite'
    ) INTO column_exists;

    IF column_exists THEN
        RAISE NOTICE 'Dropping sources.isFavorite column';
        ALTER TABLE "sources" DROP COLUMN "isFavorite" CASCADE;
    END IF;

    -- Check and drop category
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sources' AND column_name = 'category'
    ) INTO column_exists;

    IF column_exists THEN
        RAISE NOTICE 'Dropping sources.category column';
        ALTER TABLE "sources" DROP COLUMN "category" CASCADE;
    END IF;

    -- Check and drop tags
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'sources' AND column_name = 'tags'
    ) INTO column_exists;

    IF column_exists THEN
        RAISE NOTICE 'Dropping sources.tags column';
        ALTER TABLE "sources" DROP COLUMN "tags" CASCADE;
    END IF;
END $$;

-- ITEMS TABLE: Must HAVE category and tags
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check and add category
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'items' AND column_name = 'category'
    ) INTO column_exists;

    IF NOT column_exists THEN
        RAISE NOTICE 'Adding items.category column';
        ALTER TABLE "items" ADD COLUMN "category" VARCHAR(100) DEFAULT NULL;
    END IF;

    -- Check and add tags
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'items' AND column_name = 'tags'
    ) INTO column_exists;

    IF NOT column_exists THEN
        RAISE NOTICE 'Adding items.tags column';
        ALTER TABLE "items" ADD COLUMN "tags" TEXT[] DEFAULT NULL;
    END IF;
END $$;

-- COLUMNS TABLE: Must HAVE isSmartColumn and smartFilter
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check and add isSmartColumn
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'columns' AND column_name = 'isSmartColumn'
    ) INTO column_exists;

    IF NOT column_exists THEN
        RAISE NOTICE 'Adding columns.isSmartColumn column';
        ALTER TABLE "columns" ADD COLUMN "isSmartColumn" BOOLEAN DEFAULT false;
    END IF;

    -- Check and add smartFilter
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'columns' AND column_name = 'smartFilter'
    ) INTO column_exists;

    IF NOT column_exists THEN
        RAISE NOTICE 'Adding columns.smartFilter column';
        ALTER TABLE "columns" ADD COLUMN "smartFilter" JSONB DEFAULT NULL;
    END IF;
END $$;

-- Recreate necessary indexes
CREATE INDEX IF NOT EXISTS "items_category_idx" ON "items"("userId", "category") WHERE "category" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "items_tags_idx" ON "items" USING GIN("tags") WHERE "tags" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "items_is_bookmarked_idx" ON "items"("userId", "isBookmarked") WHERE "isBookmarked" = true;
CREATE INDEX IF NOT EXISTS "columns_is_smart_column_idx" ON "columns"("userId", "deckId", "isSmartColumn") WHERE "isSmartColumn" = true;

-- Final verification query to log the state
DO $$
DECLARE
    sources_cols TEXT;
    items_cols TEXT;
    columns_cols TEXT;
BEGIN
    -- Get sources columns
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO sources_cols
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'sources';

    RAISE NOTICE 'Sources table columns: %', sources_cols;

    -- Get items columns
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO items_cols
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'items';

    RAISE NOTICE 'Items table columns: %', items_cols;

    -- Get columns columns
    SELECT string_agg(column_name, ', ' ORDER BY ordinal_position)
    INTO columns_cols
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'columns';

    RAISE NOTICE 'Columns table columns: %', columns_cols;
END $$;
