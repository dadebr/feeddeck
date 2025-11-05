import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { FeedEntry } from "https://deno.land/x/rss@1.0.0/src/types/mod.ts";
import { Redis } from "https://deno.land/x/redis@v0.32.0/mod.ts";
import { unescape } from "https://raw.githubusercontent.com/lodash/lodash/4.17.21-es/lodash.js";

import { ISource } from "../models/source.ts";
import { IItem } from "../models/item.ts";
import { IProfile } from "../models/profile.ts";
import { utils } from "../utils/index.ts";
import { feedutils } from "./utils/index.ts";

export const getStackoverflowFeed = async (
  _supabaseClient: SupabaseClient,
  _redisClient: Redis | undefined,
  _profile: IProfile,
  source: ISource,
  feedData: string | undefined,
): Promise<{ source: ISource; items: IItem[] }> => {
  if (!source.options?.stackoverflow || !source.options?.stackoverflow?.type) {
    throw new feedutils.FeedValidationError("Invalid source options");
  }

  if (source.options.stackoverflow.type === "tag") {
    source.options.stackoverflow.url = `https://stackoverflow.com/feeds/tag?tagnames=${source.options.stackoverflow.tag}&sort=${source.options.stackoverflow.sort}`;
  }

  if (!source.options?.stackoverflow.url) {
    throw new feedutils.FeedValidationError("Invalid source options");
  }

  /**
   * Get the RSS for the provided `stackoverflow` url and parse it. If a feed
   * doesn't contains a title we return an error.
   */
  const feed = await feedutils.getAndParseFeed(
    source.options.stackoverflow.url,
    source,
    feedData,
  );

  if (!feed.title.value) {
    throw new Error("Invalid feed");
  }

  /**
   * Generate a source id based on the user id, column id and the normalized
   * `stackoverflow` url. Besides that we also set the source type to
   * `stackoverflow` and set the title and link for the source.
   */
  if (source.id === "") {
    source.id = await feedutils.generateSourceId("stackoverflow", 
      source.userId,
      source.columnId,
      source.options.stackoverflow.url,
    );
  }
  source.type = "stackoverflow";
  source.title = feed.title.value;
  if (feed.links.length > 0) {
    source.link = feed.links[0];
  }
  source.icon = undefined;

  /**
   * Now that the source does contain all the required information we can start
   * to generate the items for the source, by looping over all the feed entries.
   */
  const items: IItem[] = [];

  for (const [index, entry] of feed.entries.entries()) {
    if (feedutils.shouldSkipEntry(index, entry, source.updatedAt || 0)) {
      continue;
    }

    /**
     * Create the item object and add it to the `items` array.
     */
    items.push({
      id: await feedutils.generateItemId(source.id, entry.id),
      userId: source.userId,
      columnId: source.columnId,
      sourceId: source.id,
      title: entry.title!.value!,
      link: entry.links[0].href!,
      media: undefined,
      description: entry.description?.value
        ? unescape(entry.description.value)
        : undefined,
      author: undefined,
      publishedAt: Math.floor(entry.published!.getTime() / 1000),
    });
  }

  return { source, items };
};

/**
 * `skipEntry` is used to determin if an entry should be skipped or not. When a
 * entry in the RSS feed is skipped it will not be added to the database. An
/**
 * entry will be skipped when
 * - it is not within the first 50 entries of the feed, because we only keep the
 *   last 50 items of each source in our delete logic.
 * - the entry does not contain a title, a link or a published date.
 * - the published date of the entry is older than the last update date of the
 *   source minus 10 seconds.
 */
/**
 * `generateSourceId` generates a unique source id based on the user id, column
 * id and the link of the RSS feed. We use the MD5 algorithm for the link to
/**
 * `generateItemId` generates a unique item id based on the source id and the
 * identifier of the item. We use the MD5 algorithm for the identifier, which
