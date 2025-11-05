import { FeedEntry } from "https://deno.land/x/rss@1.0.0/src/types/mod.ts";
import { utils } from "../../utils/index.ts";

/**
 * Configuration options for feed parsing
 */
export interface FeedParserConfig {
  /**
   * Maximum number of items to process from a feed
   * @default 50
   */
  maxItems?: number;

  /**
   * Time buffer in seconds for considering items as new
   * @default 10
   */
  timeBuffer?: number;
}

const DEFAULT_CONFIG: Required<FeedParserConfig> = {
  maxItems: 50,
  timeBuffer: 10,
};

/**
 * `generateSourceId` generates a unique source id based on the source type,
 * user id, column id and a unique identifier (usually the feed URL).
 * We use the MD5 algorithm for the identifier to generate a deterministic hash.
 *
 * @param sourceType - The type of the source (e.g., 'rss', 'youtube', 'mastodon')
 * @param userId - The ID of the user who owns the source
 * @param columnId - The ID of the column containing the source
 * @param identifier - A unique identifier for the source (usually the feed URL)
 * @returns A unique source ID in the format: `{sourceType}-{userId}-{columnId}-{md5(identifier)}`
 *
 * @example
 * ```typescript
 * const sourceId = await generateSourceId(
 *   'rss',
 *   'user-123',
 *   'column-456',
 *   'https://example.com/feed.xml'
 * );
 * // Returns: 'rss-user-123-column-456-abc123...'
 * ```
 */
export const generateSourceId = async (
  sourceType: string,
  userId: string,
  columnId: string,
  identifier: string,
): Promise<string> => {
  const hash = await utils.md5(identifier);
  return `${sourceType}-${userId}-${columnId}-${hash}`;
};

/**
 * `generateItemId` generates a unique item id based on the source id and an
 * identifier for the item. We use the MD5 algorithm for the identifier to
 * generate a deterministic hash.
 *
 * The identifier can be:
 * - The item's unique ID from the feed (if available)
 * - The item's URL/link (as fallback)
 * - Any other unique identifier for the item
 *
 * @param sourceId - The ID of the source containing the item
 * @param identifier - A unique identifier for the item (ID, URL, etc.)
 * @returns A unique item ID in the format: `{sourceId}-{md5(identifier)}`
 *
 * @example
 * ```typescript
 * const itemId = await generateItemId(
 *   'rss-user-123-column-456-abc',
 *   'https://example.com/article/123'
 * );
 * // Returns: 'rss-user-123-column-456-abc-def456...'
 * ```
 */
export const generateItemId = async (
  sourceId: string,
  identifier: string,
): Promise<string> => {
  const hash = await utils.md5(identifier);
  return `${sourceId}-${hash}`;
};

/**
 * `shouldSkipEntry` determines if a feed entry should be skipped during processing.
 * An entry will be skipped when:
 *
 * 1. The entry index exceeds the maximum items limit (default: 50)
 * 2. The entry is missing required fields
 * 3. The entry's published date is older than the source's last update time
 *
 * @param index - The zero-based index of the entry in the feed
 * @param entry - The feed entry to evaluate
 * @param sourceUpdatedAt - Unix timestamp (in seconds) of when the source was last updated
 * @param config - Optional configuration for parsing behavior
 * @returns `true` if the entry should be skipped, `false` otherwise
 *
 * @example
 * ```typescript
 * const entry = feed.entries[0];
 * const skip = shouldSkipEntry(0, entry, source.updatedAt || 0);
 * if (skip) {
 *   continue; // Skip processing this entry
 * }
 * ```
 */
export const shouldSkipEntry = (
  index: number,
  entry: FeedEntry,
  sourceUpdatedAt: number,
  config: FeedParserConfig = {},
): boolean => {
  const { maxItems, timeBuffer } = { ...DEFAULT_CONFIG, ...config };

  // Skip if we've reached the maximum number of items
  if (index >= maxItems) {
    return true;
  }

  // Skip if missing essential fields
  if (!hasRequiredFields(entry)) {
    return true;
  }

  // Skip if the entry is older than the source's last update
  const entryTimestamp = getEntryTimestamp(entry);
  if (entryTimestamp !== null && entryTimestamp <= sourceUpdatedAt - timeBuffer) {
    return true;
  }

  return false;
};

/**
 * `hasRequiredFields` checks if a feed entry contains the minimum required fields
 * for processing. At minimum, an entry must have a link.
 *
 * @param entry - The feed entry to validate
 * @returns `true` if the entry has required fields, `false` otherwise
 */
export const hasRequiredFields = (entry: FeedEntry): boolean => {
  // Must have at least one link with a valid href
  if (!entry.links || entry.links.length === 0 || !entry.links[0]?.href) {
    return false;
  }

  return true;
};

/**
 * `getEntryTimestamp` extracts the published/updated timestamp from a feed entry.
 * It tries multiple fields in order of preference:
 * 1. entry.published
 * 2. entry.updated
 * 3. entry["dc:date"]
 *
 * @param entry - The feed entry to extract the timestamp from
 * @returns Unix timestamp in seconds, or null if no valid date is found
 */
export const getEntryTimestamp = (entry: FeedEntry): number | null => {
  // Try published date first
  if (entry.published) {
    return Math.floor(entry.published.getTime() / 1000);
  }

  // Try updated date as fallback
  if (entry.updated) {
    return Math.floor(entry.updated.getTime() / 1000);
  }

  // Try Dublin Core date as last resort
  if (entry["dc:date"]) {
    return getDCDateTimestamp(entry["dc:date"]);
  }

  return null;
};

/**
 * `getDCDateTimestamp` extracts the timestamp from a Dublin Core date field.
 * The dc:date field can be either a Date object or an object with a value property.
 *
 * @param dcdate - The Dublin Core date value
 * @returns Unix timestamp in seconds
 */
export const getDCDateTimestamp = (dcdate: Date | { value: Date }): number => {
  if (dcdate instanceof Date) {
    return Math.floor(dcdate.getTime() / 1000);
  } else {
    return Math.floor(dcdate.value.getTime() / 1000);
  }
};

/**
 * `validateRequiredFeedFields` validates that a feed entry has specific required fields.
 * This is useful for source-specific validation beyond the basic requirements.
 *
 * @param entry - The feed entry to validate
 * @param requiredFields - Array of field names that must be present and truthy
 * @returns `true` if all required fields are present, `false` otherwise
 *
 * @example
 * ```typescript
 * // Validate that entry has title and published date
 * const valid = validateRequiredFeedFields(entry, ['title.value', 'published']);
 * ```
 */
export const validateRequiredFeedFields = (
  entry: FeedEntry,
  requiredFields: string[],
): boolean => {
  for (const fieldPath of requiredFields) {
    const value = getNestedValue(entry, fieldPath);
    if (!value) {
      return false;
    }
  }
  return true;
};

/**
 * Helper function to get a nested value from an object using dot notation
 */
// deno-lint-ignore no-explicit-any
const getNestedValue = (obj: any, path: string): any => {
  return path.split('.').reduce((current, part) => current?.[part], obj);
};

/**
 * `logSkippedEntry` logs information about a skipped entry for debugging purposes.
 * Only logs in debug mode to avoid cluttering production logs.
 *
 * @param reason - The reason why the entry was skipped
 * @param entry - The feed entry that was skipped
 * @param index - The index of the entry in the feed
 */
export const logSkippedEntry = (
  reason: string,
  entry: FeedEntry,
  index?: number,
): void => {
  const indexInfo = index !== undefined ? ` at index ${index}` : '';
  const link = entry.links?.[0]?.href || 'unknown';

  utils.log('debug', `Skipped entry${indexInfo}: ${reason}`, {
    link,
    hasTitle: !!entry.title?.value,
    hasPublished: !!entry.published,
    hasUpdated: !!entry.updated,
  });
};
