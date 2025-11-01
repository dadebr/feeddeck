------------------------------------------------------------------------------------------------------------------------
-- Revert the incorrect implementation that added metadata fields to sources table.
-- These fields should be on items table instead, as we want to categorize individual feed items, not entire sources.
------------------------------------------------------------------------------------------------------------------------

-- Drop indexes
DROP INDEX IF EXISTS "sources_is_favorite_idx";
DROP INDEX IF EXISTS "sources_category_idx";

-- Drop columns from sources table
ALTER TABLE "sources"
DROP COLUMN IF EXISTS "isFavorite",
DROP COLUMN IF EXISTS "category",
DROP COLUMN IF EXISTS "tags";
