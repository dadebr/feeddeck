import { assertEquals, assertNotEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  generateSourceId,
  generateItemId,
  shouldSkipEntry,
  hasRequiredFields,
  getEntryTimestamp,
  getDCDateTimestamp,
} from "../common.ts";
import type { FeedEntry } from "https://deno.land/x/rss@1.0.0/src/types/mod.ts";

/**
 * Test utilities for common feed parsing functions
 */

// Helper to create mock feed entries
const createMockEntry = (overrides?: Partial<FeedEntry>): FeedEntry => ({
  id: "test-entry-123",
  title: { value: "Test Entry" },
  links: [{ href: "https://example.com/article" }],
  published: new Date(),
  ...overrides,
} as FeedEntry);

/**
 * Tests for generateSourceId
 */
Deno.test("generateSourceId: creates deterministic IDs", async () => {
  const id1 = await generateSourceId("rss", "user1", "col1", "https://example.com/feed");
  const id2 = await generateSourceId("rss", "user1", "col1", "https://example.com/feed");

  assertEquals(id1, id2, "Same inputs should produce same ID");
});

Deno.test("generateSourceId: different URLs produce different IDs", async () => {
  const id1 = await generateSourceId("rss", "user1", "col1", "https://example.com/feed1");
  const id2 = await generateSourceId("rss", "user1", "col1", "https://example.com/feed2");

  assertNotEquals(id1, id2, "Different URLs should produce different IDs");
});

Deno.test("generateSourceId: different source types produce different IDs", async () => {
  const id1 = await generateSourceId("rss", "user1", "col1", "https://example.com/feed");
  const id2 = await generateSourceId("youtube", "user1", "col1", "https://example.com/feed");

  assertNotEquals(id1, id2, "Different source types should produce different IDs");
});

Deno.test("generateSourceId: includes source type prefix", async () => {
  const id = await generateSourceId("rss", "user1", "col1", "https://example.com/feed");

  assertEquals(id.startsWith("rss-"), true, "ID should start with source type");
});

/**
 * Tests for generateItemId
 */
Deno.test("generateItemId: creates deterministic IDs", async () => {
  const id1 = await generateItemId("source-123", "https://example.com/article");
  const id2 = await generateItemId("source-123", "https://example.com/article");

  assertEquals(id1, id2, "Same inputs should produce same ID");
});

Deno.test("generateItemId: different identifiers produce different IDs", async () => {
  const id1 = await generateItemId("source-123", "https://example.com/article1");
  const id2 = await generateItemId("source-123", "https://example.com/article2");

  assertNotEquals(id1, id2, "Different identifiers should produce different IDs");
});

/**
 * Tests for shouldSkipEntry
 */
Deno.test("shouldSkipEntry: respects default maxItems (50)", () => {
  const entry = createMockEntry();

  assertEquals(shouldSkipEntry(49, entry, 0), false, "Entry 49 should not be skipped");
  assertEquals(shouldSkipEntry(50, entry, 0), true, "Entry 50 should be skipped (default limit)");
});

Deno.test("shouldSkipEntry: respects custom maxItems config", () => {
  const entry = createMockEntry();

  assertEquals(
    shouldSkipEntry(99, entry, 0, { maxItems: 100 }),
    false,
    "Entry 99 should not be skipped with maxItems=100"
  );
  assertEquals(
    shouldSkipEntry(100, entry, 0, { maxItems: 100 }),
    true,
    "Entry 100 should be skipped with maxItems=100"
  );
});

Deno.test("shouldSkipEntry: skips entries missing required fields", () => {
  const entryWithoutLink = createMockEntry({ links: [] });

  assertEquals(
    shouldSkipEntry(0, entryWithoutLink, 0),
    true,
    "Entry without link should be skipped"
  );
});

Deno.test("shouldSkipEntry: detects stale entries based on timestamp", () => {
  const now = Math.floor(Date.now() / 1000);

  // Fresh entry (5 seconds old)
  const freshEntry = createMockEntry({
    published: new Date((now - 5) * 1000),
  });

  // Stale entry (20 seconds old, beyond 10-second buffer)
  const staleEntry = createMockEntry({
    published: new Date((now - 20) * 1000),
  });

  assertEquals(
    shouldSkipEntry(0, freshEntry, now),
    false,
    "Fresh entry should not be skipped"
  );
  assertEquals(
    shouldSkipEntry(0, staleEntry, now),
    true,
    "Stale entry should be skipped"
  );
});

Deno.test("shouldSkipEntry: respects custom timeBuffer", () => {
  const now = Math.floor(Date.now() / 1000);

  // Entry 15 seconds old
  const entry = createMockEntry({
    published: new Date((now - 15) * 1000),
  });

  assertEquals(
    shouldSkipEntry(0, entry, now, { timeBuffer: 10 }),
    true,
    "Entry should be skipped with 10-second buffer"
  );
  assertEquals(
    shouldSkipEntry(0, entry, now, { timeBuffer: 20 }),
    false,
    "Entry should not be skipped with 20-second buffer"
  );
});

/**
 * Tests for hasRequiredFields
 */
Deno.test("hasRequiredFields: validates entry has link", () => {
  const validEntry = createMockEntry();
  const invalidEntry = createMockEntry({ links: [] });

  assertEquals(hasRequiredFields(validEntry), true, "Valid entry should pass");
  assertEquals(hasRequiredFields(invalidEntry), false, "Entry without link should fail");
});

/**
 * Tests for getEntryTimestamp
 */
Deno.test("getEntryTimestamp: extracts published timestamp", () => {
  const date = new Date("2025-01-01T12:00:00Z");
  const entry = createMockEntry({ published: date });

  const timestamp = getEntryTimestamp(entry);

  assertEquals(
    timestamp,
    Math.floor(date.getTime() / 1000),
    "Should extract published timestamp"
  );
});

Deno.test("getEntryTimestamp: falls back to updated timestamp", () => {
  const date = new Date("2025-01-01T12:00:00Z");
  const entry = createMockEntry({
    published: undefined,
    updated: date,
  } as Partial<FeedEntry>);

  const timestamp = getEntryTimestamp(entry);

  assertEquals(
    timestamp,
    Math.floor(date.getTime() / 1000),
    "Should fall back to updated timestamp"
  );
});

Deno.test("getEntryTimestamp: returns null for entries without dates", () => {
  const entry = createMockEntry({
    published: undefined,
    updated: undefined,
  } as Partial<FeedEntry>);

  const timestamp = getEntryTimestamp(entry);

  assertEquals(timestamp, null, "Should return null when no date is available");
});

/**
 * Tests for getDCDateTimestamp
 */
Deno.test("getDCDateTimestamp: handles Date object", () => {
  const date = new Date("2025-01-01T12:00:00Z");
  const timestamp = getDCDateTimestamp(date);

  assertEquals(
    timestamp,
    Math.floor(date.getTime() / 1000),
    "Should extract timestamp from Date object"
  );
});

Deno.test("getDCDateTimestamp: handles object with value property", () => {
  const date = new Date("2025-01-01T12:00:00Z");
  const dcDate = { value: date };
  const timestamp = getDCDateTimestamp(dcDate);

  assertEquals(
    timestamp,
    Math.floor(date.getTime() / 1000),
    "Should extract timestamp from dc:date object"
  );
});

console.log("\n✅ All common utility tests passed!");
