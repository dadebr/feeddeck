import { getFavicon } from "./getFavicon.ts";
import { uploadSourceIcon } from "./uploadFile.ts";
import { getAndParseFeed } from "./getAndParseFeed.ts";
import { assertEqualsItems, assertEqualsSource } from "./test.ts";
import { FeedGetAndParseError, FeedValidationError } from "./errors.ts";
import {
  generateSourceId,
  generateItemId,
  shouldSkipEntry,
  hasRequiredFields,
  getEntryTimestamp,
  getDCDateTimestamp,
  validateRequiredFeedFields,
  logSkippedEntry,
} from "./common.ts";

export type { Favicon } from "./getFavicon.ts";
export type { FeedParserConfig } from "./common.ts";

export const feedutils = {
  getFavicon,
  uploadSourceIcon,
  assertEqualsItems,
  assertEqualsSource,
  getAndParseFeed,
  FeedValidationError,
  FeedGetAndParseError,
  generateSourceId,
  generateItemId,
  shouldSkipEntry,
  hasRequiredFields,
  getEntryTimestamp,
  getDCDateTimestamp,
  validateRequiredFeedFields,
  logSkippedEntry,
};
