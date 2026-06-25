---
name: js-prefs
description: Use when editing, creating, or refactoring any JavaScript/TypeScript/React file (`.js`/`.jsx`/`.ts`/`.tsx`) in the Buildout repo. Mike's personal style conventions — function handlers, named exports, import ordering, braced ifs, `||` fallbacks, Select generics, update/change verbs, JSX prop sorting, components/ui/button usage. Auto-injected by the PreToolUse hook on matching edits; also invocable as /js-prefs.
---

# JavaScript / TypeScript / React preferences (Mike)

Personal style defaults for any `.js`/`.jsx`/`.ts`/`.tsx` edit, creation, or refactor in this repo. These are about *my* style; the project's `react-edit-rules` skill (component hierarchy, no new Redux, etc.) is separate and still applies. Not absolute — if Mike waives a rule, honor it and note it. Don't churn untouched code to conform (see general-prefs: minimal diffs).

## Handlers & helpers — `function`, not arrow
Inside a React component body, declare handlers and inline helpers with `function x() { ... }`, not `const x = () => { ... }`. Matches the component declaration and hoists. Module-level non-component functions are already plain `function` — unaffected.

## Named exports for new modules
New React components (and other new modules) use named exports — `export function Foo() { ... }` + `import { Foo } from '...'` — not `export default`. Existing files with `export default` are left alone even when touched; don't convert import sites just to switch. Split: "did I create this file this turn?" → named; "was it already here?" → leave the default.

## Import ordering
Blank-line-separated blocks, fixed order:

1. **React** — `react`, `prop-types`
2. **External / third-party** — node_modules (except redux, below)
3. **Redux** — `react-redux` grouped with the internal action/selector/store imports it pairs with
4. **Internal** — own project, **including Blueprint** (`@buildoutinc/*` counts as internal): `components/`, `bundles/`, `helpers/`, `shared/`, relative `./` `../`
5. **Type imports** — prefer inlining onto an import above; break out standalone only when needed
6. **Styles** — `import './x.scss'`, always last

Within each block: default imports first, then named (`{ … }`). Mike produces this with vim `:sort` (whole-line) — since `{` sorts after every letter, named imports naturally land after defaults. A new named import belongs at the END of the block, NOT alphabetized among the defaults. Apply to imports you add/change; don't bulk-reorder untouched files.

## Always brace `if` statements
Never write a single-line `if` (alone or with `else`). Always brace and break across lines. Ternaries / `&&` / `||` expressions are fine — this is about `if` *statements*.

```ts
// bad
if (open === previous.current) return;
if (open) onOpen?.(); else onClose?.();
// good
if (open === previous.current) {
  return;
}
```

## `||` for label/string fallbacks
Use `||` (not `??`) when defaulting a label or user-facing string: `options.foo?.label || 'Default'`. An empty string is never a valid label and should fall through. Reserve `??` for numeric/boolean cases where `0`/`false` are legitimately distinct from "not provided."

## `update` vs `change` verbs
`update` implies a network request (`updateContact` hits the server); `change` implies purely local state (`changeContactRole` mutates the store only). Name `onChange`/`change` for local-only setters; reserve `update` for calls that result in a request.

## `<Select>` — no reflexive generics
For `components/ui/select`'s `<Select>`, omit the explicit type generic (`<Select<Broker>>`) — TS infers `Option` from `options`/`value`/a typed `onChange`, including the async path. The one footgun: passing a raw `useState` setter directly as `onChange` (`onChange={setBroker}`) leaks the functional-updater overload into the inferred type. Fix by wrapping — `onChange={broker => setBroker(broker)}` — not by adding a generic. Leave existing explicit generics in place; this is for new code.

## JSX prop sorting (eslint error)
`react/jsx-sort-props` is enforced as an **error**: props alphabetical, callbacks/`on*` last, case-insensitive, no reservedFirst (`ref`/`key` sort alphabetically). When adding/renaming a prop, insert it in alphabetical position (`className`, `icon`, `size`, `variant`, then `onClick`).

## components/ui/button conventions
- **Defaults:** `variant: 'primary'` and `size: 'default'` are the cva defaults — omit them. Migrating `Button.Primary` → just `<Button>`.
- **Icons via props:** pass icons through `icon` (leading) / `iconEnd` (trailing), never as a `<FontAwesomeIcon>` child — the wrapper renders the icon itself and applies icon-button sizing.
- **Multi-line threshold:** single line when ≤4 non-label props and within 120 chars; one-prop-per-line only when >4 non-label props or over 120. Prefer the `label` prop, but use children if `label` would force multi-line when children keep it on one line.

## Don't run full Jest mid-work
Don't run the full `yarn test` suite while iterating (~1080 suites, too slow) — run a targeted subset by path/area. `--findRelatedTests` is unreliable here. Save the full suite for the end (Mike runs it himself).
