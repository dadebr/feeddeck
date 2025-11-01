------------------------------------------------------------------------------------------------------------------------
-- Comprehensive cleanup to fix all broken references after removing source metadata fields
-- This migration ensures no triggers, functions, or constraints reference the removed columns
------------------------------------------------------------------------------------------------------------------------

-- First, drop any triggers that might be causing issues
DROP TRIGGER IF EXISTS sources_metadata_update ON "sources";

-- Drop any views that might reference the old columns
DROP VIEW IF EXISTS sources_with_metadata;
DROP VIEW IF EXISTS favorite_sources;

-- Ensure all indexes related to removed fields are gone
DROP INDEX IF EXISTS "sources_tags_idx";
DROP INDEX IF EXISTS "sources_is_favorite_idx";
DROP INDEX IF EXISTS "sources_category_idx";

-- Ensure the columns are completely removed (idempotent operation)
DO $$
BEGIN
    -- Drop isFavorite if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sources' AND column_name = 'isFavorite'
    ) THEN
        ALTER TABLE "sources" DROP COLUMN "isFavorite";
    END IF;

    -- Drop category if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sources' AND column_name = 'category'
    ) THEN
        ALTER TABLE "sources" DROP COLUMN "category";
    END IF;

    -- Drop tags if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sources' AND column_name = 'tags'
    ) THEN
        ALTER TABLE "sources" DROP COLUMN "tags";
    END IF;
END $$;

-- Verify items table has the correct columns
DO $$
BEGIN
    -- Add category to items if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'items' AND column_name = 'category'
    ) THEN
        ALTER TABLE "items" ADD COLUMN "category" VARCHAR(100) DEFAULT NULL;
        CREATE INDEX IF NOT EXISTS "items_category_idx" ON "items"("userId", "category") WHERE "category" IS NOT NULL;
    END IF;

    -- Add tags to items if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'items' AND column_name = 'tags'
    ) THEN
        ALTER TABLE "items" ADD COLUMN "tags" TEXT[] DEFAULT NULL;
        CREATE INDEX IF NOT EXISTS "items_tags_idx" ON "items" USING GIN("tags") WHERE "tags" IS NOT NULL;
    END IF;
END $$;

-- Verify columns table has smart column fields
DO $$
BEGIN
    -- Add isSmartColumn if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'columns' AND column_name = 'isSmartColumn'
    ) THEN
        ALTER TABLE "columns" ADD COLUMN "isSmartColumn" BOOLEAN DEFAULT false;
    END IF;

    -- Add smartFilter if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'columns' AND column_name = 'smartFilter'
    ) THEN
        ALTER TABLE "columns" ADD COLUMN "smartFilter" JSONB DEFAULT NULL;
    END IF;
END $$;

-- Create index for smart columns if it doesn't exist
CREATE INDEX IF NOT EXISTS "columns_is_smart_column_idx"
ON "columns"("userId", "deckId", "isSmartColumn")
WHERE "isSmartColumn" = true;

-- Recreate the bookmarked items index if it doesn't exist
CREATE INDEX IF NOT EXISTS "items_is_bookmarked_idx"
ON "items"("userId", "isBookmarked")
WHERE "isBookmarked" = true;

-- Add helpful comments
COMMENT ON COLUMN "items"."isBookmarked" IS 'Serves dual purpose: bookmark for later reading AND favorite/star functionality';
COMMENT ON COLUMN "items"."category" IS 'User-defined category for organizing feed items (e.g., Technology, News, Sports)';
COMMENT ON COLUMN "items"."tags" IS 'Array of user-defined tags for flexible item organization';
COMMENT ON COLUMN "columns"."smartFilter" IS 'JSONB object defining smart column criteria. Examples: {"type": "favorites"} or {"type": "category", "value": "Technology"}';
