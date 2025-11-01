------------------------------------------------------------------------------------------------------------------------
-- Add metadata fields to items table for categorization and tagging of individual feed items.
-- Note: isBookmarked already exists and serves as the "favorite" functionality.
-- We're adding category and tags to allow users to organize their feed items.
------------------------------------------------------------------------------------------------------------------------

-- Add category column to items table
ALTER TABLE "items"
ADD COLUMN "category" VARCHAR(100) DEFAULT NULL;

-- Add tags column to items table (array of strings for multiple tags per item)
ALTER TABLE "items"
ADD COLUMN "tags" TEXT[] DEFAULT NULL;

-- Create index for category filtering (only index non-null values for efficiency)
CREATE INDEX IF NOT EXISTS "items_category_idx"
ON "items"("userId", "category")
WHERE "category" IS NOT NULL;

-- Create index for tags filtering using GIN index for array containment queries
CREATE INDEX IF NOT EXISTS "items_tags_idx"
ON "items" USING GIN("tags")
WHERE "tags" IS NOT NULL;

-- Create index for bookmarked items (favorites)
CREATE INDEX IF NOT EXISTS "items_is_bookmarked_idx"
ON "items"("userId", "isBookmarked")
WHERE "isBookmarked" = true;

-- Add comment to clarify that isBookmarked serves as favorite functionality
COMMENT ON COLUMN "items"."isBookmarked" IS 'Serves dual purpose: bookmark for later reading AND favorite/star functionality';
COMMENT ON COLUMN "items"."category" IS 'User-defined category for organizing feed items (e.g., Technology, News, Sports)';
COMMENT ON COLUMN "items"."tags" IS 'Array of user-defined tags for flexible item organization';
