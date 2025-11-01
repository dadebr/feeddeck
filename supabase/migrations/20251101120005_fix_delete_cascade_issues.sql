------------------------------------------------------------------------------------------------------------------------
-- Fix DELETE CASCADE issues that may be causing 500 errors
-- This migration ensures all triggers and constraints work correctly after field removal
------------------------------------------------------------------------------------------------------------------------

-- Drop any problematic views that might reference old columns
DROP VIEW IF EXISTS sources_metadata CASCADE;
DROP VIEW IF EXISTS source_categories CASCADE;
DROP VIEW IF EXISTS favorite_sources CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sources_with_stats CASCADE;

-- Ensure the sources_delete_file trigger is using the correct search_path
-- This was updated in a later migration but we want to make sure it's correct
DROP TRIGGER IF EXISTS sources_delete_file ON "sources";
DROP FUNCTION IF EXISTS sources_delete_file();

CREATE OR REPLACE FUNCTION sources_delete_file()
RETURNS trigger
LANGUAGE plpgsql
SECURITY definer
SET search_path = ''
AS $$
DECLARE
  supabase_api_url TEXT;
  supabase_service_role_key TEXT;
BEGIN
  SELECT value INTO supabase_api_url FROM public.settings WHERE name = 'supabase_api_url';
  SELECT value INTO supabase_service_role_key FROM public.settings WHERE name = 'supabase_service_role_key';

  IF (old.icon IS NOT NULL AND NOT starts_with(old.icon, 'https://')) THEN
    PERFORM
      net.http_delete(
        url:=supabase_api_url||'/storage/v1/object/sources/'||old.icon,
        headers:=('{"Authorization": "Bearer ' || supabase_service_role_key || '"}')::jsonb
      );
  END IF;

  RETURN old;
END;
$$;

CREATE TRIGGER sources_delete_file
AFTER DELETE ON "sources"
FOR EACH ROW
EXECUTE FUNCTION sources_delete_file();

-- Verify that all RLS policies are correctly set
-- Sometimes old policies can cause 500 errors if they reference non-existent columns

-- Re-enable RLS (should already be enabled, but just to be safe)
ALTER TABLE "sources" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "columns" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "items" ENABLE ROW LEVEL SECURITY;

-- Log current state for debugging
DO $$
DECLARE
    trigger_count INTEGER;
    policy_count INTEGER;
BEGIN
    -- Count triggers on sources table
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE event_object_schema = 'public' AND event_object_table = 'sources';

    RAISE NOTICE 'Sources table has % triggers', trigger_count;

    -- Count policies on columns table
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'columns';

    RAISE NOTICE 'Columns table has % RLS policies', policy_count;
END $$;
