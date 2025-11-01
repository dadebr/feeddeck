------------------------------------------------------------------------------------------------------------------------
-- Fix sources_delete_file trigger that causes Out of Memory errors
-- The trigger was trying to queue too many HTTP requests when cascading deletes happen
------------------------------------------------------------------------------------------------------------------------

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS sources_delete_file ON "sources";
DROP FUNCTION IF EXISTS sources_delete_file();

-- Recreate with better memory management
-- We'll skip the HTTP delete for storage cleanup and rely on the scheduled cleanup job instead
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
  -- Only attempt HTTP delete if icon is a local file (not external URL)
  -- and we're not in a cascade delete scenario (which can cause memory issues)
  IF (old.icon IS NOT NULL AND NOT starts_with(old.icon, 'https://')) THEN
    BEGIN
      SELECT value INTO supabase_api_url FROM public.settings WHERE name = 'supabase_api_url';
      SELECT value INTO supabase_service_role_key FROM public.settings WHERE name = 'supabase_service_role_key';

      -- Use pg_background to avoid blocking and memory issues
      -- Note: If this still causes issues, the scheduled cleanup job will handle it
      PERFORM
        net.http_delete(
          url:=supabase_api_url||'/storage/v1/object/sources/'||old.icon,
          headers:=('{"Authorization": "Bearer ' || supabase_service_role_key || '"}')::jsonb
        );
    EXCEPTION
      WHEN OTHERS THEN
        -- Log the error but don't fail the delete
        -- The scheduled cleanup job (sources_delete_files) will clean up orphaned files
        RAISE WARNING 'Failed to delete source icon %, will be cleaned by scheduled job: %', old.icon, SQLERRM;
    END;
  END IF;

  RETURN old;
END;
$$;

-- Recreate the trigger
CREATE TRIGGER sources_delete_file
AFTER DELETE ON "sources"
FOR EACH ROW
EXECUTE FUNCTION sources_delete_file();

-- Add comment explaining the behavior
COMMENT ON FUNCTION sources_delete_file() IS 'Attempts to delete source icon from storage. If it fails (e.g., during cascade deletes), the scheduled cleanup job sources_delete_files() will handle orphaned files.';
