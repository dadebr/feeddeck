------------------------------------------------------------------------------------------------------------------------
-- Fix any remaining issues after reverting source metadata fields
-- This migration ensures all indexes and constraints related to the removed columns are properly cleaned up
------------------------------------------------------------------------------------------------------------------------

-- Drop any remaining indexes that might have been missed
DROP INDEX IF EXISTS "sources_tags_idx";
DROP INDEX IF EXISTS "sources_is_favorite_idx";
DROP INDEX IF EXISTS "sources_category_idx";

-- Ensure the sources table columns are completely removed (idempotent)
ALTER TABLE "sources" DROP COLUMN IF EXISTS "isFavorite";
ALTER TABLE "sources" DROP COLUMN IF EXISTS "category";
ALTER TABLE "sources" DROP COLUMN IF EXISTS "tags";

-- No need to modify triggers or RLS policies as they don't reference the removed columns
