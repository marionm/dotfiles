---
name: ruby-prefs
description: Use when editing, creating, or refactoring any Ruby (`.rb`) file in the Buildout repo. Mike's personal Ruby/Rails style conventions — method naming, hash shorthand, guards/indentation, block variable names, FastSerializer entry point, unmerged migrations. Auto-injected by the PreToolUse hook on `.rb` edits; also invocable as /ruby-prefs.
---

# Ruby / Rails preferences (Mike)

Personal style defaults for any `.rb` edit, creation, or refactor in this repo. Not absolute — if Mike waives a rule for a one-off, honor it and note which rule was waived. Don't rewrite pre-existing code that violates these just because you touched the file (see general-prefs: minimal diffs); apply during genuine cleanup of code you're already changing, at most flag the rest.

## Method naming — verby for arg-takers, nouns for getters
Methods that compute or take arguments get **verby** names (`get_`, `build_`, `fetch_`). Argumentless getters stay nouns.

- Arg-taking / computing → `get_collection_path(company)`, `build_url(...)`, `fetch_api(account)`.
- Argumentless getter → noun: `def api; ...; end`, attr readers.
- `get_`/`set_` are fine here. `Naming/AccessorMethodName` only flags *argumentless* `get_x` (and one-arg `set_x`); `get_foo(arg)` is not flagged and the codebase has ~500 `def get_*`. Don't rename `get_foo(arg)` to dodge a cop that isn't firing.

Mike corrected renames of `get_api`/`get_path` into `api_for`/`collection_path` — don't noun-ify arg-taking methods.

## Hash & kwarg shorthand (Ruby 3.1+)
When the key and an in-scope variable/method share a name, use the bare-colon form:

- `{ user:, login_credential: }` not `{ user: user, login_credential: login_credential }`
- `Ai::Function.call(name, args, login_credential:, user:)` not `(..., login_credential: login_credential)`
- `new(foo:, bar:)` not `new(foo: foo, bar: bar)`

Only fall back to longhand when the value isn't an identically-named identifier (`{ user: current_user }`, `foo(name: record.name)`). The linter rewrites longhand on save — match it up front.

## Guards & indentation
- **Guard clauses only for longer bodies.** A guard (`return unless ...`) protecting one or two lines reads worse than wrapping the body in a normal `if`. Trust rubocop — it flags when a guard would actually be preferable for the block size. Good: `do_thing if a && b && c` or an `if ... end` block.
- **Always 2-space indent.** Never align continuation lines to an operator, opening paren, or previous token. Prefer one-liners when reasonable, else 2-space continuation.

## Block & local variable names
No extreme shorthand — neither single-letter (`k`, `c`, `i`, `dt`) nor initial-letter (`cr`, `lc`). Use the unqualified word or full name. Applies to block vars AND local assignments, on cleanup as well as net-new.

```ruby
# bad
commissions.find { |c| c["name"] == ... }
contact_roles.find { |cr| cr["role"] == ... }
lease_terms.each_with_index.all? { |_, i| ... }
dt = tool.deal_fields["deal_type"]
# good
commissions.find { |commission| commission["name"] == ... }
contact_roles.find { |contact_role| contact_role["role"] == ... }
lease_terms.each_with_index.all? { |_, index| ... }
deal_type = tool.deal_fields["deal_type"]
```
OK exceptions: `acc` for an `each_with_object` accumulator, `_` for ignored args. Plain `i` is NOT OK — use `index`.

## FastSerializer — `.new` vs `.serialize`
Open the serializer and check how it preloads before choosing the entry point:

- No preloading, or per-attribute preloading (`preload:` on `attribute` / `with_preloading`) → `ThingSerializer.new(thing, params: { ... })`.
- Grouped whole-collection preloading (overridden `def preload(items, ...)` / `associations_to_preload_by_attribute`) → `ThingSerializer.serialize(records, params)`.

`.serialize` is the legacy path; per-attribute preloading (BatchLoader) is the direction forward and does not run through it. `.serialize(item)` on a single record already just returns `new(item, params:)`, so switching is behavior-preserving.

## Unmerged migrations — amend in place
When a schema tweak is needed and the migration that introduced the table/column is **unmerged** (created on this feature branch, not yet on master), edit that migration in place and update `db/schema.rb` to match — don't `rails generate` a new incremental migration. Only add a new migration when the original is already merged/released. Caveat: editing an already-run migration needs `db:rollback` + `db:migrate` (or `db:migrate:redo`) to take effect on an existing dev DB.
