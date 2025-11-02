import { createClient } from "jsr:@supabase/supabase-js@2";

import { corsHeaders } from "../_shared/utils/cors.ts";
import { getFeed } from "../_shared/feed/feed.ts";
import { ISource } from "../_shared/models/source.ts";
import { IProfile } from "../_shared/models/profile.ts";
import { utils } from "../_shared/utils/index.ts";
import {
  FEEDDECK_SUPABASE_ANON_KEY,
  FEEDDECK_SUPABASE_SERVICE_ROLE_KEY,
  FEEDDECK_SUPABASE_URL,
} from "../_shared/utils/constants.ts";

/**
 * The `refresh-column-v1` edge function is used to manually refresh all sources
 * in a column. It expects a POST request with a columnId. The function will fetch
 * all sources for the column, update their feeds, and save the new items to the
 * database.
 */
Deno.serve(async (req) => {
  /**
   * We need to handle the preflight request for CORS as it is described in the
   * Supabase documentation: https://supabase.com/docs/guides/functions/cors
   */
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    /**
     * Create a new Supabase client with the anonymous key and the authorization
     * header from the request. This allows us to access the database as the
     * user that is currently signed in.
     */
    const userSupabaseClient = createClient(
      FEEDDECK_SUPABASE_URL,
      FEEDDECK_SUPABASE_ANON_KEY,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    /**
     * Get the user from the request. If there is no user, we return an error.
     */
    const {
      data: { user },
    } = await userSupabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json; charset=utf-8",
        },
        status: 401,
      });
    }

    /**
     * Create a new admin client for Supabase, which is used in the following
     * steps to access the database. This client is required because the user
     * client does not have the permissions to access the `profiles` table or to
     * update rows in the `sources` and `items` table.
     */
    const adminSupabaseClient = createClient(
      FEEDDECK_SUPABASE_URL,
      FEEDDECK_SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    /**
     * Get the user profile from the database. If there is no profile or more
     * than one profile, we return an error.
     */
    const { data: profile, error: profileError } = await adminSupabaseClient
      .from("profiles")
      .select("*")
      .eq("id", user.id);
    if (profileError || profile?.length !== 1) {
      utils.log("error", "Failed to get user profile", {
        user: user,
        error: profileError,
      });
      return new Response(
        JSON.stringify({ error: "Failed to get user profile" }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json; charset=utf-8",
          },
          status: 500,
        },
      );
    }

    /**
     * Get the columnId from the request body
     */
    const reqData: { columnId: string } = await req.json();

    /**
     * Verify that the column belongs to the user
     */
    const { data: column, error: columnError } = await adminSupabaseClient
      .from("columns")
      .select("id")
      .eq("id", reqData.columnId)
      .eq("userId", user.id);

    if (columnError || !column || column.length === 0) {
      utils.log("error", "Failed to get column or unauthorized", {
        columnId: reqData.columnId,
        userId: user.id,
        error: columnError,
      });
      return new Response(
        JSON.stringify({ error: "Column not found or unauthorized" }),
        {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json; charset=utf-8",
          },
          status: 403,
        },
      );
    }

    /**
     * Get all sources for the column
     */
    const { data: sources, error: sourcesError } = await adminSupabaseClient
      .from("sources")
      .select("*")
      .eq("columnId", reqData.columnId)
      .eq("userId", user.id);

    if (sourcesError) {
      utils.log("error", "Failed to get sources", {
        error: sourcesError,
      });
      return new Response(JSON.stringify({ error: "Failed to get sources" }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json; charset=utf-8",
        },
        status: 500,
      });
    }

    /**
     * Update each source by fetching new feed data
     */
    let updatedCount = 0;
    const errors: Array<{ sourceId: string; error: string }> = [];

    for (const source of sources || []) {
      try {
        // Skip deprecated source types
        if (source.type === "nitter") {
          continue;
        }

        const { source: updatedSource, items } = await getFeed(
          adminSupabaseClient,
          undefined,
          profile[0] as IProfile,
          source as ISource,
          undefined,
        );

        // Update the source
        const { error: sourceError } = await adminSupabaseClient
          .from("sources")
          .upsert(updatedSource);

        if (sourceError) {
          utils.log("error", "Failed to update source", {
            sourceId: source.id,
            error: sourceError,
          });
          errors.push({
            sourceId: source.id,
            error: "Failed to update source",
          });
          continue;
        }

        // Insert new items if any
        if (items.length > 0) {
          const { error: itemsError } = await adminSupabaseClient
            .from("items")
            .upsert(items);

          if (itemsError) {
            utils.log("error", "Failed to save items", {
              sourceId: source.id,
              error: itemsError,
            });
            errors.push({
              sourceId: source.id,
              error: "Failed to save items",
            });
            continue;
          }
        }

        updatedCount++;
        utils.log("info", "Successfully updated source", {
          sourceId: source.id,
          itemsCount: items.length,
        });
      } catch (err) {
        utils.log("error", "Failed to refresh source", {
          sourceId: source.id,
          error: err,
        });
        errors.push({
          sourceId: source.id,
          error: err instanceof Error ? err.message : "Unknown error",
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        updatedCount,
        totalSources: sources?.length || 0,
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json; charset=utf-8",
        },
        status: 200,
      },
    );
  } catch (err) {
    utils.log("error", "An unexpected error occurred", {
      error: err,
    });
    return new Response(
      JSON.stringify({ error: "An unexpected error occurred" }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json; charset=utf-8",
        },
        status: 500,
      },
    );
  }
});
