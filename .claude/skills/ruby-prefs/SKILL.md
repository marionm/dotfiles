---
name: ruby-prefs
description: Use when editing, creating, or refactoring any Ruby (`.rb`) file in the Buildout repo. Mike's personal Ruby/Rails style conventions — method naming, hash shorthand, guards/indentation, block variable names, FastSerializer entry point, unmerged migrations, no reaching into internals, spec conventions (real objects over doubles, one source of truth for values). Auto-injected by the PreToolUse hook on `.rb` edits (specs included); also invocable as /ruby-prefs.
---

# Ruby / Rails preferences (Mike)

Personal style defaults for any `.rb` edit, creation, or refactor in this repo. Not absolute — if Mike waives a rule for a one-off, honor it and note which rule was waived. Don't rewrite pre-existing code that violates these just because you touched the file (see general-prefs: minimal diffs); apply during genuine cleanup of code you're already changing, at most flag the rest.

## No reaching into internals
Never read or write another object's private state to get your work done: no `instance_variable_get` / `instance_variable_set`, and no `send`/`__send__` to invoke a private method. Go through the public API. If what you need isn't exposed, that's a design signal — add a reader, or observe/stub at a public seam — not a license to reach past the interface. This holds everywhere, not just specs: in a spec, stub a public method (e.g. the callback registrar an object exposes), never `obj.instance_variable_get(:@provider)`.

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

## Specs — real objects over doubles
Prefer real instances to `instance_double`/mocks. Build the thing: `build`/`build_stubbed` (no DB), `create` only when persistence is actually needed (associations, `find_by`, serialization that reads the record). Reserve doubles/stubs for genuine externals you must not invoke — network/LLM calls (e.g. `Apex::Ai::BuildDeal.call`), third-party SDKs, S3. A real object exercises real behavior and catches drift an `instance_double` hides.

**Never stub ActiveRecord itself — this is a hard rule, not a preference.** Do not stub or mock persistence/query methods on a model or relation: `create!`/`create`/`new`/`save`/`update!`/`update`/`destroy`/`find`/`find_by`/`where`/`last`/`first`/`reload`, etc. Use a real record (`build`/`build_stubbed`/`create`) against the real test DB instead. Stubbing these is brittle for a specific, dangerous reason: `allow(Model).to receive(:create!).and_return(double)` **fabricates a return type the real call would never produce**, so the spec stays green while production raises. Concrete burn: `Ai::Chat#ask` returns an in-memory `RubyLLM::Message` (the AR row is saved via a callback), *not* the chat's AR record — a spec that stubbed `Ai::Chat.create!`/`ask` to return an AR double sailed past a real `NoMethodError` on `update!`. If you catch yourself stubbing a model method to avoid the DB or the network, stop: use a factory for the DB part, and stub only the genuine external **at its boundary** (WebMock/VCR for the HTTP call) — never by faking your own model's return value.
- To keep a real class exercised while still asserting on it, use `allow(Klass).to receive(:new).and_call_original` + `have_received(:new).with(...)` — assert its *inputs*, not a faked return.
- Don't compare a FastSerializer's `as_json` for equality: it returns lazy `BatchLoader` proxies that only resolve at JSON-encode time, so two calls never `==`. Assert it was built with the right record + params instead.

## Specs — one source of truth for values
Never copy/paste a literal that appears in both setup and an expectation (id, key, token, path). Extract it to a `let` and reference it in both, or read it off the created record — never hardcode a factory's default in an assertion (assert `record.x`). Derive related values by interpolation (`"prefix/#{request_id}.pdf"`) and reference `params[:x]` in assertions rather than retyping. Never assert exact error-message strings — assert behavior (status, state, whether a collaborator was called); for pass-throughs use an arbitrary `let` and check it round-trips. Same for incidental values: when only existence or a property matters, assert the property (`be_positive`, presence, a range) — don't pin the exact literal. Asserting a config default is `25` turns a harmless tuning change into a red build; assert that a sane default *exists* instead. And never repeat a constant or its arithmetic across examples (the limit *and* limit+1) — put it in one `let` and derive the rest.

## Specs — chaining matchers on a block expectation
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

## Specs — no `describe "#perform"` in worker specs
A worker spec's whole point is `#perform`, so don't wrap its examples in a `describe "#perform"` block — put the `it`s directly under the top-level `RSpec.describe Worker`. Only add a `describe ".method"` for a *distinct* method on the worker (e.g. a class method like `.stash_file`).

## Specs — never test private methods directly
Don't reach into a private method to test it — no `send(:private_method, ...)`, and don't make it public just to cover it. Exercise it through the object's public API (`run`, `perform`, `call`). If a private method's behavior can't be reached/observed through the public interface, treat that as a signal to restructure — or to just skip the test — not to poke at internals. Mike rejected a `send(:tag_exchange, ...)` unit test as bad and preferred no test over it; simpler, safer production code needs isolating tests less anyway.
