---
name: general-prefs
description: Use on any code or config edit, and when reviewing a branch, in the Buildout repo. Mike's cross-language working conventions — minimal diffs, comment discipline, no column alignment, Unix-philosophy methods, lint-before-done, batch verification, simple `git diff master` reviews. Auto-injected by the PreToolUse hook on code/config edits; also invocable as /general-prefs.
---

# General working preferences (Mike)

Cross-language defaults (Ruby, JS/TS, configs) for any code edit. Language-specific style lives in `ruby-prefs` and `js-prefs`.

## Minimal diffs — prefer Edit
Keep diffs as small as the change requires. Modify existing files with targeted `Edit`s on the specific lines — do **not** re-`Write` a whole file from memory (it silently reverts/alters unrelated lines and buries the real change in review noise). Leave pre-existing code alone — even code that violates a preference — unless changing it *is* the task; at most flag it. Reach for `Write` only for brand-new files or a full replacement Mike asked for.

## Comments — why, not what
Comments explain a non-obvious *why*, and only when the why is genuinely interesting. Never restate *what* the code does — the code shows that. No comment is completely fine. Banned: describing evident behavior ("Notify the pipeline, then close the modal"); facts that rot ("Shared by the X and Y modals" on a generic hook). Before writing a comment, ask "is this a non-obvious why?" If it describes behavior, callers, or return values, delete it.

## No column alignment
Never pad tokens into visual columns across lines (routes `to:`, hash values, `=` in assignments, trailing comments). Single space, let lines be ragged. Alignment creates blast radius — the next longer token forces re-padding every line (noisy diff) or the block goes ragged anyway. `get "user_account", to: "user_accounts#show"`, not `get  "user_account",  to: ...`.

## Unix-philosophy methods
A method should do one thing well. Favor small, single-purpose, side-effect-free functions over methods that both compute *and* mutate/orchestrate. When a method computes a value and applies it, prefer splitting — return the computed value and let the caller own the side effect. Lean toward more, smaller methods.

## Lint before declaring done
Run the linter after editing — `compile:check` (tsc) only type-checks and misses lint diagnostics.
- **JS/TS:** `yarn eslint <changed files>` (no `lint` script; binary in `node_modules/.bin`). Recurring miss: `react/jsx-sort-props`.
- **Ruby:** run rubocop. Recurring miss: hash shorthand `{ name: }`.

**Only fix violations on lines you touched** — leave pre-existing violations on untouched lines alone.

## Batch verification
For the same mechanical change across many files, run `compile:check` / eslint **once after all edits**, not per-file. Edit everything first, then a single verification pass.

## Simple branch diffs
For a branch review, use `git diff master` to see everything at once — don't separate committed vs staged vs unstaged. Primary commands: `git diff master` and `git log master..HEAD --oneline`.

## Routing "remember this" requests
When Mike asks you to remember a preference, **first evaluate whether it belongs in one of these preference skills** (`ruby-prefs`, `js-prefs`, `general-prefs`) rather than as a standalone memory file:

- Reusable style / workflow rule that should shape how code is generated → add it to the matching skill (Ruby → `ruby-prefs`, JS/TS/React → `js-prefs`, cross-cutting → `general-prefs`). Confirm which skill before writing.
- Genuine project/codebase fact or external reference (a quirk of the repo, a URL, a behavioral gotcha) → keep it as a memory file as usual.

When in doubt, ask Mike which destination he wants.
