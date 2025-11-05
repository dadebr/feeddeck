/**
 * Extended types for RSS feed parsing
 *
 * This file provides proper TypeScript interfaces for feed extensions that are
 * commonly used by various feed sources but not defined in the base RSS types.
 *
 * These types eliminate the need for unsafe 'as any' casts throughout the codebase.
 */

import type {
  Feed,
  FeedEntry,
} from "https://deno.land/x/rss@1.0.0/src/types/mod.ts";

/**
 * iTunes podcast feed extensions
 * @see https://help.apple.com/itc/podcasts_connect/#/itcb54353390
 */
export interface PodcastFeed extends Feed {
  "itunes:image"?: {
    href: string;
  };
  "itunes:author"?: {
    value: string;
  };
  "itunes:summary"?: {
    value: string;
  };
  "itunes:explicit"?: {
    value: string;
  };
  "itunes:category"?: {
    text: string;
  };
}

/**
 * Reddit feed entry extensions
 */
export interface RedditFeedEntry extends FeedEntry {
  "media:thumbnail"?: {
    url: string;
  };
}

/**
 * YouTube feed entry extensions
 * @see https://developers.google.com/youtube/v3/guides/implementation/videos
 */
export interface YoutubeFeedEntry extends FeedEntry {
  "media:group"?: {
    "media:description"?: {
      value: string;
    };
    "media:thumbnail"?: {
      url: string;
    };
    "media:content"?: Array<{
      url: string;
      type: string;
      medium: string;
    }>;
  };
}

/**
 * Google News feed entry extensions
 */
export interface GoogleNewsFeedEntry extends FeedEntry {
  source?: {
    value: string;
  };
}

/**
 * Media RSS extensions (used by many feeds)
 * @see http://www.rssboard.org/media-rss
 */
export interface MediaFeedEntry extends FeedEntry {
  "media:content"?: Array<{
    url?: string;
    medium?: string;
    type?: string;
    width?: number;
    height?: number;
  }>;
  "media:thumbnail"?: {
    url: string;
    width?: number;
    height?: number;
  };
  "media:thumbnails"?: {
    url: string;
  };
  "media:group"?: Array<{
    "media:content"?: Array<{
      url?: string;
      medium?: string;
      type?: string;
    }>;
    "media:description"?: {
      value: string;
    };
  }>;
}

/**
 * Type guard to check if a feed is a podcast feed
 */
export function isPodcastFeed(feed: Feed): feed is PodcastFeed {
  return "itunes:image" in feed || "itunes:author" in feed;
}

/**
 * Type guard to check if an entry has media extensions
 */
export function hasMediaExtensions(entry: FeedEntry): entry is MediaFeedEntry {
  return "media:content" in entry || "media:thumbnail" in entry || "media:group" in entry;
}

/**
 * Type guard to check if an entry is from Reddit
 */
export function isRedditEntry(entry: FeedEntry): entry is RedditFeedEntry {
  return "media:thumbnail" in entry;
}

/**
 * Type guard to check if an entry is from YouTube
 */
export function isYoutubeEntry(entry: FeedEntry): entry is YoutubeFeedEntry {
  return "media:group" in entry;
}

/**
 * Type guard to check if an entry is from Google News
 */
export function isGoogleNewsEntry(entry: FeedEntry): entry is GoogleNewsFeedEntry {
  return "source" in entry;
}

/**
 * Helper to safely access nested feed properties
 *
 * @param obj The feed or entry object
 * @param path Dot-separated path to the property (e.g., "itunes:image.href")
 * @returns The value if found, undefined otherwise
 */
// deno-lint-ignore no-explicit-any
export function safelyAccessFeedProperty(obj: any, path: string): any {
  return path.split('.').reduce((current, prop) => current?.[prop], obj);
}
