#!/usr/bin/env -S deno run --allow-read --allow-write

/**
 * Script to automatically refactor feed parsers to use common utilities
 */

const PARSERS_TO_REFACTOR = [
  { file: "reddit.ts", sourceType: "reddit" },
  { file: "lemmy.ts", sourceType: "lemmy" },
  { file: "medium.ts", sourceType: "medium" },
  { file: "podcast.ts", sourceType: "podcast" },
  { file: "googlenews.ts", sourceType: "googlenews" },
  { file: "pinterest.ts", sourceType: "pinterest" },
  { file: "tumblr.ts", sourceType: "tumblr" },
  { file: "stackoverflow.ts", sourceType: "stackoverflow" },
  { file: "fourchan.ts", sourceType: "fourchan" },
  { file: "nitter.ts", sourceType: "nitter" },
];

async function refactorParser(filename: string, sourceType: string) {
  const filePath = `/home/user/feeddeck/supabase/functions/_shared/feed/${filename}`;

  console.log(`Refactoring ${filename}...`);

  try {
    let content = await Deno.readTextFile(filePath);

    // 1. Replace generateSourceId calls
    const generateSourceIdPattern = new RegExp(
      `await generateSourceId\\(\\s*source\\.userId,\\s*source\\.columnId,\\s*([^)]+)\\s*\\)`,
      'g'
    );
    content = content.replace(
      generateSourceIdPattern,
      `await feedutils.generateSourceId("${sourceType}", source.userId, source.columnId, $1)`
    );

    // 2. Replace generateItemId calls
    content = content.replace(
      /await generateItemId\(/g,
      'await feedutils.generateItemId('
    );

    // 3. Replace skipEntry calls
    content = content.replace(
      /skipEntry\(index, entry, source\.updatedAt \|\| 0\)/g,
      'feedutils.shouldSkipEntry(index, entry, source.updatedAt || 0)'
    );

    // 4. Replace bare catch blocks with logging
    content = content.replace(
      /} catch \(_\) \{([^}]*?)return undefined;([^}]*?)\}/gs,
      (match, before, after) => {
        return `} catch (err) {${before}utils.log("debug", "Error in ${sourceType} parser", {
      error: err instanceof Error ? err.message : String(err),
    });
    return undefined;${after}}`;
      }
    );

    // 5. Remove duplicate function definitions
    const functionsToRemove = [
      /\/\*\*[\s\S]*?\*\/\s*const skipEntry[\s\S]*?return false;\s*};/g,
      /\/\*\*[\s\S]*?\*\/\s*const generateSourceId[\s\S]*?};/g,
      /\/\*\*[\s\S]*?\*\/\s*const generateItemId[\s\S]*?};/g,
    ];

    for (const pattern of functionsToRemove) {
      content = content.replace(pattern, '');
    }

    // 6. Clean up multiple blank lines
    content = content.replace(/\n{3,}/g, '\n\n');

    await Deno.writeTextFile(filePath, content);
    console.log(`✓ Successfully refactored ${filename}`);

  } catch (error) {
    console.error(`✗ Error refactoring ${filename}:`, error);
  }
}

async function main() {
  console.log("Starting batch refactoring of feed parsers...\n");

  for (const { file, sourceType } of PARSERS_TO_REFACTOR) {
    await refactorParser(file, sourceType);
  }

  console.log("\n✓ Batch refactoring complete!");
}

main();
