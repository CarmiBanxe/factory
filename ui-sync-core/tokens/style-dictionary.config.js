/**
 * Factory canonical Style Dictionary config.
 * Source: factory/ui-sync-core/tokens/
 * Drift-checked by: factory-watchdog Mode 3 check #8
 *
 * JS format required — Style Dictionary JSON configs do not support
 * environment variable interpolation. JS enables TOKEN_OUTPUT_DIR override.
 *
 * Usage:
 *   npx style-dictionary build --config tokens/style-dictionary.config.js
 *   TOKEN_OUTPUT_DIR=dist/tokens/ npx style-dictionary build --config tokens/style-dictionary.config.js
 */

const path = require("path");

const OUTPUT_DIR = process.env.TOKEN_OUTPUT_DIR || "tokens/output/";
const buildPath = OUTPUT_DIR.endsWith("/") ? OUTPUT_DIR : OUTPUT_DIR + "/";

module.exports = {
  source: [path.join(__dirname, "banxe-tokens.json")],
  platforms: {
    css: {
      transformGroup: "css",
      prefix: "banxe",
      buildPath,
      files: [
        {
          destination: "banxe-tokens.css",
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
      prefix: "banxe",
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
