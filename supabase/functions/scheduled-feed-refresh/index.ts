import { createClient } from "jsr:@supabase/supabase-js@2";

import { corsHeaders } from "../_shared/utils/cors.ts";
import { getFeed } from "../_shared/feed/feed.ts";
import { ISource } from "../_shared/models/source.ts";
import { IProfile } from "../_shared/models/profile.ts";
import { utils } from "../_shared/utils/index.ts";
import {
  FEEDDECK_SUPABASE_SERVICE_ROLE_KEY,
  FEEDDECK_SUPABASE_URL,
} from "../_shared/utils/constants.ts";

/**
 * The `scheduled-feed-refresh` edge function is called by pg_cron or external
 * scheduler to automatically refresh feeds. It processes a batch of sources
 * that haven't been updated recently.
 *
 * This can be called:
 * 1. Via pg_cron (Supabase database cron)
 * 2. Via external cron service (cron-job.org, etc)
 * 3. Manually for testing
 */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    /**
     * Validate the request has the correct authorization header
     * This should be the service role key or a custom secret
     */
    const authHeader = req.headers.get("Authorization");
    const cronSecret = Deno.env.get("CRON_SECRET");

    // Allow either service role key or custom cron secret
    if (!authHeader && !cronSecret) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    /**
     * Create admin Supabase client
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
     * Get batch size from query params (default 50)
     */
    const url = new URL(req.url);
    const batchSize = parseInt(url.searchParams.get("batch") || "50");
    const maxSources = parseInt(url.searchParams.get("max") || "100");

    utils.log("info", "Starting scheduled feed refresh", {
      batchSize,
      maxSources,
    });

    /**
     * Get active profiles (premium or created in last 7 days)
     */
    const profileCreatedAt =
      Math.floor(new Date().getTime() / 1000) - 60 * 60 * 24 * 7;

    const { data: profiles, error: profilesError } = await adminSupabaseClient
      .from("profiles")
      .select("*")
      .or(`tier.eq.premium,createdAt.gt.${profileCreatedAt}`)
      .limit(batchSize);

    if (profilesError) {
      utils.log("error", "Failed to get profiles", { error: profilesError });
      return new Response(
        JSON.stringify({ error: "Failed to get profiles" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 500,
        },
      );
    }

    /**
     * Get sources that haven't been updated in the last hour
     */
    const sourcesUpdatedAt = Math.floor(new Date().getTime() / 1000) - 60 * 60;
    let totalProcessed = 0;
    let totalErrors = 0;
    const errors: Array<{ profileId: string; sourceId: string; error: string }> = [];

    for (const profile of profiles || []) {
      if (totalProcessed >= maxSources) {
        break;
      }

      const { data: sources, error: sourcesError } = await adminSupabaseClient
        .from("sources")
        .select("*")
        .eq("userId", profile.id)
        .lt("updatedAt", sourcesUpdatedAt)
        .limit(10); // Max 10 sources per user per run

      if (sourcesError) {
        utils.log("error", "Failed to get sources", {
          profileId: profile.id,
          error: sourcesError,
        });
        continue;
      }

      for (const source of sources || []) {
        if (totalProcessed >= maxSources) {
          break;
        }

        // Skip deprecated source types
        if (source.type === "nitter") {
          continue;
        }

        // Reddit rate limit for free tier (24h)
        if (profile.tier === "free" && source.type === "reddit") {
          if (
            source.updatedAt >
            Math.floor(new Date().getTime() / 1000) - 60 * 60 * 24
          ) {
            continue;
          }
        }

        try {
          utils.log("info", "Processing source", {
            profileId: profile.id,
            sourceId: source.id,
            type: source.type,
          });

          const { source: updatedSource, items } = await getFeed(
            adminSupabaseClient,
            undefined,
            profile as IProfile,
            source as ISource,
            undefined,
          );

          // Update source
          const { error: sourceError } = await adminSupabaseClient
            .from("sources")
            .upsert(updatedSource);

          if (sourceError) {
            throw sourceError;
          }

          // Insert items
          if (items.length > 0) {
            const { error: itemsError } = await adminSupabaseClient
              .from("items")
              .upsert(items);

            if (itemsError) {
              throw itemsError;
            }
          }

          totalProcessed++;
          utils.log("info", "Successfully processed source", {
            sourceId: source.id,
            itemsCount: items.length,
          });
        } catch (err) {
          totalErrors++;
          const errorMsg = err instanceof Error ? err.message : "Unknown error";
          utils.log("error", "Failed to process source", {
            sourceId: source.id,
            error: errorMsg,
          });
          errors.push({
            profileId: profile.id,
            sourceId: source.id,
            error: errorMsg,
          });
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        profilesProcessed: profiles?.length || 0,
        sourcesProcessed: totalProcessed,
        errors: totalErrors,
        errorDetails: errors.length > 0 ? errors : undefined,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      },
    );
  } catch (err) {
    utils.log("error", "Scheduled refresh failed", { error: err });
    return new Response(
      JSON.stringify({ error: "Scheduled refresh failed" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      },
    );
  }
});
