---
name: find-importers
description: Find which files import a TypeScript/JavaScript module using ts-morph for accurate Webpack resolution
argument-hint: <file-path> [-d [depth]]
allowed-tools: Bash, Read, Glob
---

# Find Importers

Use the `find-importers` script to discover which files import a given TypeScript or JavaScript module. This uses ts-morph for accurate import resolution (respecting Webpack aliases, tsconfig paths, etc.) rather than grep which can miss or mismatch imports.

## When to Use

- Finding all consumers of a component, hook, utility, or module
- Understanding the impact of changing or removing a file
- Tracing import trees to understand dependencies

## Usage

```bash
# Find immediate importers of a file
/Users/mikemarion/.local/bin/find-importers $ARGUMENTS

# Examples:
# /Users/mikemarion/.local/bin/find-importers app/javascript/components/Button.tsx
# /Users/mikemarion/.local/bin/find-importers -d app/javascript/shared/hooks/useApi.ts
# /Users/mikemarion/.local/bin/find-importers -d 2 app/javascript/utils/format.ts
```

## Options

- No flags: Show only immediate importers (depth 1)
- `-d` or `--depth`: Show full import tree (unlimited depth)
- `-d N`: Show import tree up to N levels deep

## Output

- Without `-d`: Plain list of files that directly import the target
- With `-d`: Tree view showing the import hierarchy

## Notes

- Must be run from a directory with a `tsconfig.json` (or parent)
- Searches `app/javascript/`, `src/`, and `lib/` directories
- Supports `.ts`, `.tsx`, `.js`, `.jsx` files
