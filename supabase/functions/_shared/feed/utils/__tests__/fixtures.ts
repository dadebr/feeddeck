/**
 * Test fixtures for feed parsing tests
 *
 * This module provides reusable mock data creators for testing feed parsers.
 */

import type { Feed, FeedEntry } from "https://deno.land/x/rss@1.0.0/src/types/mod.ts";
import type { ISource } from "../../models/source.ts";
import type { IProfile } from "../../models/profile.ts";
import type { IItem } from "../../models/item.ts";

/**
 * Create a mock user profile for testing
 */
export const createMockProfile = (overrides?: Partial<IProfile>): IProfile => ({
  id: "test-user-123",
  tier: "free",
  createdAt: Math.floor(Date.now() / 1000),
  updatedAt: Math.floor(Date.now() / 1000),
  ...overrides,
});

/**
 * Create a mock feed source for testing
 */
export const createMockSource = (
  type: string,
  overrides?: Partial<ISource>
): ISource => ({
  id: "",
  userId: "test-user-123",
  columnId: "test-column-123",
  type,
  title: "",
  link: "",
  options: {},
  createdAt: Math.floor(Date.now() / 1000),
  updatedAt: Math.floor(Date.now() / 1000),
  ...overrides,
});

/**
 * Create a mock feed entry for testing
 */
export const createMockFeedEntry = (
  overrides?: Partial<FeedEntry>
): FeedEntry => ({
  id: "test-entry-123",
  title: { value: "Test Entry Title" },
  links: [{ href: "https://example.com/article" }],
  published: new Date(),
  description: { value: "Test entry description" },
  author: { name: "Test Author" },
  ...overrides,
} as FeedEntry);

/**
 * Create a mock RSS feed for testing
 */
export const createMockFeed = (overrides?: Partial<Feed>): Feed => ({
  type: "rss",
  title: { value: "Test Feed" },
  description: { value: "A test feed" },
  links: ["https://example.com"],
  entries: [
    createMockFeedEntry(),
    createMockFeedEntry({ id: "test-entry-124", title: { value: "Second Entry" } }),
  ],
  ...overrides,
} as Feed);

/**
 * Create a mock feed item for testing
 */
export const createMockItem = (overrides?: Partial<IItem>): IItem => ({
  id: "item-123",
  userId: "test-user-123",
  columnId: "test-column-123",
  sourceId: "source-123",
  title: "Test Item",
  link: "https://example.com/article",
  publishedAt: Math.floor(Date.now() / 1000),
  ...overrides,
});

/**
 * Sample RSS feed XML for testing
 */
export const SAMPLE_RSS_FEED = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>https://example.com</link>
    <description>A test feed</description>
    <item>
      <title>Test Article 1</title>
      <link>https://example.com/article1</link>
      <description>Description of test article 1</description>
      <pubDate>Mon, 01 Jan 2025 12:00:00 GMT</pubDate>
      <author>test@example.com (Test Author)</author>
    </item>
    <item>
      <title>Test Article 2</title>
      <link>https://example.com/article2</link>
      <description>Description of test article 2</description>
      <pubDate>Mon, 01 Jan 2025 11:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>`;

/**
 * Sample Atom feed XML for testing
 */
export const SAMPLE_ATOM_FEED = `<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <link href="https://example.com"/>
  <updated>2025-01-01T12:00:00Z</updated>
  <entry>
    <title>Test Entry</title>
    <link href="https://example.com/entry1"/>
    <id>https://example.com/entry1</id>
    <updated>2025-01-01T12:00:00Z</updated>
    <summary>Test entry summary</summary>
    <author>
      <name>Test Author</name>
    </author>
  </entry>
</feed>`;
