---
name: prefs
description: Mike's personal code preferences - cross-language working conventions plus Ruby/Rails and JS/TS/React specifics. Grouped by language; the General group applies to every code or config edit. Audited on demand by /cleanup; also invocable as /prefs.
---

# Working preferences (Mike)

Personal style defaults for any code edit, creation, or refactor. Not absolute - if Mike waives a
rule for a one-off, honor it and note which rule was waived. Don't rewrite pre-existing code that
violates these just because you touched the file (see "Minimal diffs"); apply during genuine cleanup
of code you're already changing, at most flag the rest.

Rules are grouped by what they apply to. **General** covers every code and config edit; the language
groups add to it rather than replacing it.

## General

Cross-language defaults (Ruby, JS/TS, configs) for any code edit. Language-specific style lives in `ruby-prefs` and `js-prefs`.

### Minimal diffs — prefer Edit
Keep diffs as small as the change requires. Modify existing files with targeted `Edit`s on the specific lines — do **not** re-`Write` a whole file from memory (it silently reverts/alters unrelated lines and buries the real change in review noise). Leave pre-existing code alone — even code that violates a preference — unless changing it *is* the task; at most flag it. Reach for `Write` only for brand-new files or a full replacement Mike asked for.

### Comments — why, not what
Comments explain a non-obvious *why*, and only when the why is genuinely interesting. Never restate *what* the code does — the code shows that. No comment is completely fine. Banned: describing evident behavior ("Notify the pipeline, then close the modal"); facts that rot ("Shared by the X and Y modals" on a generic hook). Before writing a comment, ask "is this a non-obvious why?" If it describes behavior, callers, or return values, delete it.

**Put the comment on the line it explains, not at the top of the block.** A note about why an error is swallowed belongs on the `rescue`, not above `def`. A header comment forces the reader to hold it in mind while scanning for what it refers to, and it goes stale silently when the line it described moves or goes away.

```ruby
# bad — the reader has to guess which part this is about
# ExpectationNotMetError descends from Exception, so it needs catching by name.
def verify_step(step)
  refresh
  return [true, nil] if step.verification.nil?

  [run { step.verification.call } ? true : false, nil]
rescue RSpec::Expectations::ExpectationNotMetError => e
  [false, e.message]
end

# good — it sits on the line that needs it
def verify_step(step)
  refresh
  return [true, nil] if step.verification.nil?

  [run { step.verification.call } ? true : false, nil]
  # Descends from Exception rather than StandardError, so it has to be caught by name.
rescue RSpec::Expectations::ExpectationNotMetError => e
  [false, e.message]
end
```

A comment describing the method as a whole is still fine above the `def` — the rule is that a comment about *one line* goes on that line.

### No column alignment
Never pad tokens into visual columns across lines (routes `to:`, hash values, `=` in assignments, trailing comments). Single space, let lines be ragged. Alignment creates blast radius — the next longer token forces re-padding every line (noisy diff) or the block goes ragged anyway. `get "user_account", to: "user_accounts#show"`, not `get  "user_account",  to: ...`.

### Don't be terse for its own sake
Name things for what they are, not for the fewest characters that could work. A truncated or vague name makes the reader reconstruct meaning the full word would have handed them: `def person(first, last)` — first and last *what*? `def person(first_name, last_name)` costs nothing and asks nothing.

Length is rarely the real cost, and in Ruby the fuller name is often **shorter at the call site**, because it unlocks hash shorthand:

```ruby
# bad - terse params, longhand at the call site
def person(first, last)
  create(:backoffice_contact, first_name: first, last_name: last)
end

# good - full params, shorthand
def person(first_name, last_name)
  create(:backoffice_contact, first_name:, last_name:)
end
```

Applies to parameters, locals, and block variables, in any language. Match the name to the thing it will be assigned to or passed as. See ruby-prefs "Block & local variable names" for the Ruby specifics on single- and initial-letter names.

### Oxford commas
Use them when writing — prose, comments, commit messages, docs, PR descriptions. "the driver, the judge, and the report", not "the driver, the judge and the report".

### Don't extract single-use constants
A value used once can just sit inline. Extracting it names it twice and sends the reader somewhere else to find out what it is, for no reuse in return. This goes double when the thing is **hard to name accurately** — if the best name available is a restatement of the value (`SPOKEN = %w[assistant]`, `DEFAULT_LIMIT = 20` next to the only `limit:` in the file), the constant is worse than the literal.

Extract when there is real reuse, when the value is a genuine contract (a route, an enum value, a wire key), or when the name teaches something the literal can't (`MAX_BYTES = 20.megabytes` earns its place; `HEADER = "Step"` does not). Same reasoning applies to extracting a method or a local for a single trivial use — see "Method order" and js-prefs on helpers.

### Method order — callees below callers
Add new methods **below** existing ones rather than at the top, and order a file so a reader meets the entry point first: if `A` calls `Z`, `Z` goes below `A`. Order multiple callees roughly in the order the caller reaches them. In JS this needs no ceremony because function declarations hoist — see js-prefs "Helpers go below their caller, not above" for the JS specifics, including preferring `function` over a `const` arrow when hoisting is what makes the order possible.

Don't reorder untouched code just to comply, and a file counts as untouched once its work is committed.

### Unix-philosophy methods
A method should do one thing well. Favor small, single-purpose, side-effect-free functions over methods that both compute *and* mutate/orchestrate. When a method computes a value and applies it, prefer splitting — return the computed value and let the caller own the side effect. Lean toward more, smaller methods.

### Lint before declaring done
Run the linter after editing — `compile:check` (tsc) only type-checks and misses lint diagnostics.
- **JS/TS:** `yarn eslint <changed files>` (no `lint` script; binary in `node_modules/.bin`). Recurring miss: `react/jsx-sort-props`.
- **Ruby:** run rubocop. Recurring miss: hash shorthand `{ name: }`.

**Only fix violations on lines you touched** — leave pre-existing violations on untouched lines alone.

### Batch verification
For the same mechanical change across many files, run `compile:check` / eslint **once after all edits**, not per-file. Edit everything first, then a single verification pass.

Same rule for specs, and it matters more there because they're slow. While iterating, run **only the spec file(s) covering what you just changed** — a single file, or the one directory. Save the broad sweep (a whole area like `spec/models/ai spec/queries/ai spec/requests/…`) for **once, at the end**, when the change is finished.

Don't re-run hundreds of examples after every tweak, rename, or comment edit. If a change is confined to one class, one spec file is the check. Re-verify more widely only when something actually warrants it — a rebase you resolved by hand, a rename touching many call sites, or the final pass before handing work back.

Never run two rspec processes at once (e.g. one in the background while starting another). They share the test database and produce phantom failures in unrelated specs.

### Don't assert on non-load-bearing strings
Tests must not assert the *content* of prose written to be read by a human or a model. Prose gets reworded constantly, so the assertion fails on edits that break nothing — and the pressure is then to reword the subject to keep the test green, which is backwards.

Never assert the content of:
- LLM system instructions, tool descriptions, or other prompt text
- User-facing error messages, snackbar/toast copy, labels, empty-state text

Assert the thing that would actually be broken instead: a status, a raised class, a returned shape, or whether a message is *present* at all. `expect(result["message"]).to be_present` is fine; `expect(result["message"]).to eq("The email service is temporarily unavailable.")` is not.

The exception is a string that is genuinely a contract — a route, a JSON key, an enum value — or interpolated **data** whose presence is the behavior under test (that a confirmation summary contains the recipient's address, say). Those aren't copy.

Corollary: keep example names honest. When an assertion on copy comes out, rename the example so it stops promising what it no longer checks.

### Don't write change-detector tests
A test should fail when behavior a user or caller depends on changes — not when an implementation detail moves. A test pinned so tightly to today's implementation that any refactor reddens it teaches people to update tests reflexively, which is how real failures get waved through.

**Don't inline logic or formatting that belongs to code outside the file under test.** If the subject delegates to a collaborator to build something, call that collaborator in the expectation instead of hand-reproducing its output. Hand-copied output is a second, unmaintained implementation, and it makes the wrong spec fail — a change to the collaborator breaks a test about something else entirely.

Worked example: `spec/controllers/ai/assistant_controller_spec.rb` hand-wrote every key of `Ai::AssistantActionSerializer`'s payload. Its actual subject was *which actions land on which reply, in what order*, so adding one serializer attribute broke a test about message grouping. Fixed by letting the collaborator speak:

```ruby
def serialize_actions(*actions)
  actions.map { |action| Ai::AssistantActionSerializer.new(action).as_json.deep_stringify_keys }
end

expect(response.parsed_body["messages"].last["actions"]).to eq(serialize_actions(pending, rejected))
```

That still catches the wrong records, the wrong order, keys added after serialization, and the wrong serializer — it just stops caring what the fields are, which was never the controller's business. What each thing serializes *into* belongs to that serializer's own spec.

**The line:** reuse the *collaborators* the subject delegates to; never build an expectation from the subject itself — `expect(subject.call).to eq(subject.call)` passes for every change, including wrong ones. When unsure which side of the line a test sits on, mutate it (flip the expected order, change an id) and confirm it actually fails.

### Simple branch diffs
For a branch review, use `git diff master` to see everything at once — don't separate committed vs staged vs unstaged. Primary commands: `git diff master` and `git log master..HEAD --oneline`.

### Routing "remember this" requests
When Mike asks you to remember a preference, **first evaluate whether it belongs in this skill** rather than as a standalone memory file:

- Reusable style / workflow rule that should shape how code is generated → add it here as a new `###` section under the right `##` group. Confirm the group before writing.
- Genuine project/codebase fact or external reference (a quirk of the repo, a URL, a behavioral gotcha) → keep it as a memory file as usual.

When in doubt, ask Mike which destination he wants.

### Never stage or commit for Mike
Do **not** run `git add`/`git commit` on Mike's behalf — not even when a unit of work is finished, tested, and lint-clean. Leave the working tree unstaged; just tell him what's ready and let him stage and commit himself. This holds regardless of the surrounding workflow (per-model, per-feature, etc.); "test → commit" rhythms mean *he* stages and commits, not you. Only stage/commit if he explicitly asks you to in that moment.

## Ruby / Rails

Applies to `.rb`, on top of General.

Personal style defaults for any `.rb` edit, creation, or refactor in this repo. Not absolute — if Mike waives a rule for a one-off, honor it and note which rule was waived. Don't rewrite pre-existing code that violates these just because you touched the file (see general-prefs: minimal diffs); apply during genuine cleanup of code you're already changing, at most flag the rest.

### Method naming — verby for arg-takers, nouns for getters
Methods that compute or take arguments get **verby** names (`get_`, `build_`, `fetch_`). Argumentless getters stay nouns.

- Arg-taking / computing → `get_collection_path(company)`, `build_url(...)`, `fetch_api(account)`.
- Argumentless getter → noun: `def api; ...; end`, attr readers.
- `get_`/`set_` are fine here. `Naming/AccessorMethodName` only flags *argumentless* `get_x` (and one-arg `set_x`); `get_foo(arg)` is not flagged and the codebase has ~500 `def get_*`. Don't rename `get_foo(arg)` to dodge a cop that isn't firing.

Mike corrected renames of `get_api`/`get_path` into `api_for`/`collection_path` — don't noun-ify arg-taking methods.

Past-participle names are the same mistake in disguise: a spec helper named `serialized(*actions)` reads as a value, when it *serializes* them. `serialize` is better; **`serialize_actions` is best** — name the verb *and* what it acts on. Applies to spec helpers as much as app code.

### Hash & kwarg shorthand (Ruby 3.1+)
When the key and an in-scope variable/method share a name, use the bare-colon form:

- `{ user:, login_credential: }` not `{ user: user, login_credential: login_credential }`
- `Ai::Function.call(name, args, login_credential:, user:)` not `(..., login_credential: login_credential)`
- `new(foo:, bar:)` not `new(foo: foo, bar: bar)`

Only fall back to longhand when the value isn't an identically-named identifier (`{ user: current_user }`, `foo(name: record.name)`). The linter rewrites longhand on save — match it up front.

### Guards & indentation
- **Guard clauses only for longer bodies.** A guard (`return unless ...`) protecting one or two lines reads worse than wrapping the body in a normal `if`. Trust rubocop — it flags when a guard would actually be preferable for the block size. Good: `do_thing if a && b && c` or an `if ... end` block.
- **Always 2-space indent.** Never align continuation lines to an operator, opening paren, or previous token. Prefer one-liners when reasonable, else 2-space continuation.

When a call is too long for one line, break after the opening paren and pick one of two shapes. Never half-wrap, aligning the trailing arguments under the first one:

```ruby
# bad - arguments aligned under the opening paren
create(:backoffice_contact, :person, company:, owner: company, public: true,
                                     first_name:, last_name:)

# good - arguments on their own line, 2-space indent
create(
  :backoffice_contact, :person, company:, owner: company, public: true, first_name:, last_name:
)

# also good - one per line, when that reads better or the single line is still too long
create(
  :backoffice_contact,
  :person,
  company:,
  owner: company,
  public: true,
  first_name:,
  last_name:
)
```

Alignment has the same blast radius as column alignment (see general-prefs): the next longer token forces re-indenting every line below it.

### `filter` over `select`
Prefer `filter` to its alias `select` for Enumerable filtering (`collection.filter { |x| ... }`). Same for `filter_map`. Don't rewrite existing `select` calls on untouched lines, and don't flag `select` in review — this is only the default when writing new code.

### Block & local variable names
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

### FastSerializer — `.new` vs `.serialize`
Open the serializer and check how it preloads before choosing the entry point:

- No preloading, or per-attribute preloading (`preload:` on `attribute` / `with_preloading`) → `ThingSerializer.new(thing, params: { ... })`.
- Grouped whole-collection preloading (overridden `def preload(items, ...)` / `associations_to_preload_by_attribute`) → `ThingSerializer.serialize(records, params)`.

`.serialize` is the legacy path; per-attribute preloading (BatchLoader) is the direction forward and does not run through it. `.serialize(item)` on a single record already just returns `new(item, params:)`, so switching is behavior-preserving.

### Unmerged migrations — amend in place
When a schema tweak is needed and the migration that introduced the table/column is **unmerged** (created on this feature branch, not yet on master), edit that migration in place and update `db/schema.rb` to match — don't `rails generate` a new incremental migration. Only add a new migration when the original is already merged/released. Caveat: editing an already-run migration needs `db:rollback` + `db:migrate` (or `db:migrate:redo`) to take effect on an existing dev DB.

### RSpec — test through the public API, never `send` a private method
Reaching for `obj.send(:private_method)` in a spec is a smell, and so is giving a private method its
own `describe` block — both couple the spec to internals and invite testing a helper that no caller
actually reaches the way the spec does. Exercise private behavior **indirectly** through the class's
public entry point and assert on what that returns.

When a private helper is hard to reach that way, the spec is telling you something: either the setup
needs a small purpose-built subject (a minimal concrete subclass for an abstract base, a fake that
routes through the public method), or the helper wants to be public / extracted to its own object.

```ruby
# bad - couples to internals, and names a private method in the spec structure
describe "#render_page" do
  it "..." do
    expect(tool.send(:render_page, result, page: 2)).to eq(...)
  end
end

# good - same coverage via the public entry point
describe "#call" do
  it "wraps results in a page envelope with the total match count" do
    expect(JSON.parse(tool.call({}))).to include("page" => 1, "total_count" => 137)
  end
end
```

Corollary: organize `describe` blocks around the public method or the behavior, not around each
private helper. Don't make a method public just to cover it, either — and if its behavior can't be
reached through the public interface at all, skipping the test is a better answer than poking at
internals. Mike rejected a `send(:tag_exchange, ...)` unit test as bad and preferred no test over
it; simpler production code needs isolating tests less anyway.

### No reaching into internals
Never read or write another object's private state to get your work done: no `instance_variable_get` / `instance_variable_set`, and no `send`/`__send__` to invoke a private method. Go through the public API. If what you need isn't exposed, that's a design signal — add a reader, or observe/stub at a public seam — not a license to reach past the interface. This holds everywhere, not just specs: in a spec, stub a public method (e.g. the callback registrar an object exposes), never `obj.instance_variable_get(:@provider)`.

### Specs — real objects over doubles
Prefer real instances to `instance_double`/mocks. Build the thing: `build`/`build_stubbed` (no DB), `create` only when persistence is actually needed (associations, `find_by`, serialization that reads the record). Reserve doubles/stubs for genuine externals you must not invoke — network/LLM calls (e.g. `Apex::Ai::BuildDeal.call`), third-party SDKs, S3. A real object exercises real behavior and catches drift an `instance_double` hides.

**Never stub ActiveRecord itself — this is a hard rule, not a preference.** Do not stub or mock persistence/query methods on a model or relation: `create!`/`create`/`new`/`save`/`update!`/`update`/`destroy`/`find`/`find_by`/`where`/`last`/`first`/`reload`, etc. Use a real record (`build`/`build_stubbed`/`create`) against the real test DB instead. Stubbing these is brittle for a specific, dangerous reason: `allow(Model).to receive(:create!).and_return(double)` **fabricates a return type the real call would never produce**, so the spec stays green while production raises. Concrete burn: `Ai::Chat#ask` returns an in-memory `RubyLLM::Message` (the AR row is saved via a callback), *not* the chat's AR record — a spec that stubbed `Ai::Chat.create!`/`ask` to return an AR double sailed past a real `NoMethodError` on `update!`. If you catch yourself stubbing a model method to avoid the DB or the network, stop: use a factory for the DB part, and stub only the genuine external **at its boundary** (WebMock/VCR for the HTTP call) — never by faking your own model's return value.
- To keep a real class exercised while still asserting on it, use `allow(Klass).to receive(:new).and_call_original` + `have_received(:new).with(...)` — assert its *inputs*, not a faked return.
- Don't compare a FastSerializer's `as_json` for equality: it returns lazy `BatchLoader` proxies that only resolve at JSON-encode time, so two calls never `==`. Assert it was built with the right record + params instead.

### Specs — one source of truth for values
Never copy/paste a literal that appears in both setup and an expectation (id, key, token, path). Extract it to a `let` and reference it in both, or read it off the created record — never hardcode a factory's default in an assertion (assert `record.x`). Derive related values by interpolation (`"prefix/#{request_id}.pdf"`) and reference `params[:x]` in assertions rather than retyping. Never assert exact error-message strings — assert behavior (status, state, whether a collaborator was called); for pass-throughs use an arbitrary `let` and check it round-trips. Same for incidental values: when only existence or a property matters, assert the property (`be_positive`, presence, a range) — don't pin the exact literal. Asserting a config default is `25` turns a harmless tuning change into a red build; assert that a sane default *exists* instead. And never repeat a constant or its arithmetic across examples (the limit *and* limit+1) — put it in one `let` and derive the rest.

### Specs — chaining matchers on a block expectation
When the block body fits on one line, keep `expect { ... }` on one line and put the chained matcher on the next, indented under it. Don't expand a one-statement block into `expect do … end` just because a matcher is chained off it.

```ruby
# bad
expect do
  post(:ai_summary, params: { id: property.id })
end.not_to change(SummarizePropertyWorker.jobs, :size)
# good
expect { post(:ai_summary, params: { id: property.id }) }
  .not_to change(SummarizePropertyWorker.jobs, :size)
```

Use the `expect do … end` multi-line form only when the block genuinely needs multiple statements.

### Specs — no `describe "#perform"` in worker specs
A worker spec's whole point is `#perform`, so don't wrap its examples in a `describe "#perform"` block — put the `it`s directly under the top-level `RSpec.describe Worker`. Only add a `describe ".method"` for a *distinct* method on the worker (e.g. a class method like `.stash_file`).

## JavaScript / TypeScript / React

Applies to `.js`, `.jsx`, `.ts`, `.tsx`, on top of General.

Personal style defaults for any `.js`/`.jsx`/`.ts`/`.tsx` edit, creation, or refactor in this repo. These are about *my* style; the project's `react-edit-rules` skill (component hierarchy, no new Redux, etc.) is separate and still applies. Not absolute — if Mike waives a rule, honor it and note it. Don't churn untouched code to conform (see general-prefs: minimal diffs).

### Handlers & helpers — `function`, not arrow
Inside a React component body, declare handlers and inline helpers with `function x() { ... }`, not `const x = () => { ... }`. Matches the component declaration and hoists. Module-level non-component functions are already plain `function` — unaffected.

### Named exports for new modules
New React components (and other new modules) use named exports — `export function Foo() { ... }` + `import { Foo } from '...'` — not `export default`. Existing files with `export default` are left alone even when touched; don't convert import sites just to switch. Split: "did I create this file this turn?" → named; "was it already here?" → leave the default.

### Import ordering
Blank-line-separated blocks, fixed order:

1. **React** — `react`, `prop-types`
2. **External / third-party** — node_modules (except redux, below)
3. **Redux** — `react-redux` grouped with the internal action/selector/store imports it pairs with
4. **Internal** — own project, **including Blueprint** (`@buildoutinc/*` counts as internal): `components/`, `bundles/`, `helpers/`, `shared/`, relative `./` `../`
5. **Type imports** — prefer inlining onto an import above; break out standalone only when needed
6. **Styles** — `import './x.scss'`, always last

Within each block: default imports first, then named (`{ … }`). Mike produces this with vim `:sort` (whole-line) — since `{` sorts after every letter, named imports naturally land after defaults. A new named import belongs at the END of the block, NOT alphabetized among the defaults. Apply to imports you add/change; don't bulk-reorder untouched files.

### Always brace `if` statements
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

### `||` for label/string fallbacks
Use `||` (not `??`) when defaulting a label or user-facing string: `options.foo?.label || 'Default'`. An empty string is never a valid label and should fall through. Reserve `??` for numeric/boolean cases where `0`/`false` are legitimately distinct from "not provided."

### `update` vs `change` verbs
`update` implies a network request (`updateContact` hits the server); `change` implies purely local state (`changeContactRole` mutates the store only). Name `onChange`/`change` for local-only setters; reserve `update` for calls that result in a request.

### `<Select>` — no reflexive generics
For `components/ui/select`'s `<Select>`, omit the explicit type generic (`<Select<Broker>>`) — TS infers `Option` from `options`/`value`/a typed `onChange`, including the async path. The one footgun: passing a raw `useState` setter directly as `onChange` (`onChange={setBroker}`) leaks the functional-updater overload into the inferred type. Fix by wrapping — `onChange={broker => setBroker(broker)}` — not by adding a generic. Leave existing explicit generics in place; this is for new code.

### JSX prop sorting (eslint error)
`react/jsx-sort-props` is enforced as an **error**: props alphabetical, callbacks/`on*` last, case-insensitive, no reservedFirst (`ref`/`key` sort alphabetically). When adding/renaming a prop, insert it in alphabetical position (`className`, `icon`, `size`, `variant`, then `onClick`).

### components/ui/button conventions
- **Defaults:** `variant: 'primary'` and `size: 'default'` are the cva defaults — omit them. Migrating `Button.Primary` → just `<Button>`.
- **Icons via props:** pass icons through `icon` (leading) / `iconEnd` (trailing), never as a `<FontAwesomeIcon>` child — the wrapper renders the icon itself and applies icon-button sizing.
- **Multi-line threshold:** single line when ≤4 non-label props and within 120 chars; one-prop-per-line only when >4 non-label props or over 120. Prefer the `label` prop, but use children if `label` would force multi-line when children keep it on one line.

### Don't run full Jest mid-work
Don't run the full `yarn test` suite while iterating (~1080 suites, too slow) — run a targeted subset by path/area. `--findRelatedTests` is unreliable here. Save the full suite for the end (Mike runs it himself).

### Fragment shorthand replaces the `return (` parens
When wrapping a return in a fragment would otherwise add an indentation level, put `<>`/`</>` **in place of** the `return (` … `)` parens, not nested inside them — so existing JSX keeps its current indentation instead of shifting +2. Prefer restructuring so no reindent is needed at all (e.g. render the new sibling inside an existing single-root element); reach for the fragment only when there's genuinely no single root.

```tsx
// bad — nesting <> inside the parens forces every child to reindent
return (
  <>
    <Card>…</Card>
    <Thing />
  </>
);
// good — <> takes the parens' place, children keep their indentation
return <>
  <Card>…</Card>
  <Thing />
</>;
```

### Helpers go below their caller, not above
Lean on hoisting to order a file by importance: the exported, "public" function comes first, and the unexported helpers and subcomponents it uses sit **below** it. A reader opening the file should meet the thing the file is for, not the machinery it happens to need.

```ts
// good — the export leads, its helper follows
export function readDeepLinkedSearch(tagOptions: Tag[] = []): DeepLinkedSearch | null {
  …
  return { query, contactType, tags: readTags(tagIds, tagOptions) };
}

function readTags(tagIds: string[], tagOptions: Tag[]): Tag[] {
  …
}
```

Applies to local subcomponents too — a `<Row>` used only by an exported `<Table>` belongs under it. Function declarations hoist, so this always works; if a helper is a `const` arrow function that *has* to precede its use, that's a reason to make it a `function` declaration, not a reason to move it up. Multiple helpers go below in roughly the order the exported function reaches them. Don't reorder untouched files just to comply — and a file counts as untouched once its work is committed, so don't come back later to reorder something you wrote in an earlier commit.
