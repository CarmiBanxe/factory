/**
 * Factory canonical Style Dictionary config.
 * Source: factory/ui-sync-core/tokens/
 * Drift-checked by: factory-watchdog Mode 3 check #8
 *
 * JS format required — Style Dictionary JSON configs do not support
 * environment variable interpolation. JS enables TOKEN_OUTPUT_DIR override.
 *
 * Environment overrides (defaults keep current behaviour):
 *   TOKEN_OUTPUT_DIR  output dir            (default "tokens/output/")
 *   TOKEN_SOURCE      source token file     (default "tokens.example.json")
 *   TOKEN_PREFIX      css/scss var prefix   (default "banxe")
 *   TOKEN_BASENAME    output file basename  (default "banxe" → "banxe-tokens.css")
 *
 * Usage:
 *   npx style-dictionary build --config tokens/style-dictionary.config.js
 *   TOKEN_OUTPUT_DIR=dist/tokens/ npx style-dictionary build --config tokens/style-dictionary.config.js
 *   TOKEN_SOURCE=foo-tokens.json TOKEN_PREFIX=foo TOKEN_BASENAME=foo \
 *     npx style-dictionary build --config tokens/style-dictionary.config.js
 */

const path = require("path");

const OUTPUT_DIR = process.env.TOKEN_OUTPUT_DIR || "tokens/output/";
const buildPath = OUTPUT_DIR.endsWith("/") ? OUTPUT_DIR : OUTPUT_DIR + "/";

// Domain-agnostic: factory must not hard-code a domain. Defaults preserve
// current (BANXE) behaviour until tokens are migrated in S2b.
const TOKEN_SOURCE = process.env.TOKEN_SOURCE || "tokens.example.json";
const TOKEN_PREFIX = process.env.TOKEN_PREFIX || "banxe";
const TOKEN_BASENAME = process.env.TOKEN_BASENAME || "banxe";

module.exports = {
  source: [path.join(__dirname, TOKEN_SOURCE)],
  platforms: {
    css: {
      transformGroup: "css",
      prefix: TOKEN_PREFIX,
      buildPath,
      files: [
        {
          destination: `${TOKEN_BASENAME}-tokens.css`,
          format: "css/variables",
          options: { outputReferences: true, selector: ":root" },
        },
      ],
    },
    tailwind: {
      transformGroup: "js",
      buildPath,
      files: [
        {
          destination: "tailwind-tokens.js",
          format: "javascript/module",
          options: { outputReferences: false },
        },
      ],
    },
    json: {
      transformGroup: "js",
      buildPath,
      files: [
        {
          destination: "tokens.json",
          format: "json/flat",
        },
      ],
    },
    "react-native": {
      transformGroup: "react-native",
      buildPath,
      files: [
        {
          destination: "tokens.rn.ts",
          format: "javascript/es6",
          options: { outputReferences: false },
        },
      ],
    },
    scss: {
      transformGroup: "scss",
      prefix: TOKEN_PREFIX,
      buildPath,
      files: [
        {
          destination: "_tokens.scss",
          format: "scss/variables",
        },
      ],
    },
  },
};
