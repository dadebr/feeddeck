------------------------------------------------------------------------------------------------------------------------
-- Add metadata fields to the "sources" table to support favoriting, categorization, and tagging of sources.
-- These fields enable better organization and filtering of sources across the application.
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE "sources"
ADD COLUMN "isFavorite" BOOLEAN DEFAULT false,
ADD COLUMN "category" VARCHAR(100) DEFAULT NULL,
ADD COLUMN "tags" TEXT[] DEFAULT NULL;

------------------------------------------------------------------------------------------------------------------------
-- Create indexes for better query performance on favorite and category filters
------------------------------------------------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS "sources_is_favorite_idx" ON "sources"("userId", "isFavorite") WHERE "isFavorite" = true;
CREATE INDEX IF NOT EXISTS "sources_category_idx" ON "sources"("userId", "category") WHERE "category" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "sources_tags_idx" ON "sources" USING GIN("tags") WHERE "tags" IS NOT NULL;
