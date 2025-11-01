------------------------------------------------------------------------------------------------------------------------
-- Add smart column fields to the "columns" table to support intelligent columns that aggregate items
-- based on criteria (e.g., all favorited sources, specific categories) across multiple sources.
------------------------------------------------------------------------------------------------------------------------
ALTER TABLE "columns"
ADD COLUMN "isSmartColumn" BOOLEAN DEFAULT false,
ADD COLUMN "smartFilter" JSONB DEFAULT NULL;

------------------------------------------------------------------------------------------------------------------------
-- Create index for querying smart columns efficiently
------------------------------------------------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS "columns_is_smart_column_idx" ON "columns"("userId", "deckId", "isSmartColumn") WHERE "isSmartColumn" = true;

------------------------------------------------------------------------------------------------------------------------
-- Add comment explaining smartFilter JSONB structure
-- Example structures:
-- {"type": "favorites"} - Shows items from all favorited sources
-- {"type": "category", "value": "Technology"} - Shows items from sources with specific category
-- {"type": "tags", "values": ["ai", "ml"]} - Shows items from sources with specific tags
------------------------------------------------------------------------------------------------------------------------
COMMENT ON COLUMN "columns"."smartFilter" IS 'JSONB object defining smart column criteria. Examples: {"type": "favorites"} or {"type": "category", "value": "Technology"}';
