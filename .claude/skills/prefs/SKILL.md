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

**Never name other code across a boundary.** A comment on X that names Y — who calls X, what Y guarantees before calling, who else does the same thing, or what a page does with X — is wrong as soon as a second call site appears, and it rots *silently*, because nothing about editing Y makes anyone reread X. Four shapes, all banned:

- **Who calls this.** `# Enqueued by Ai::GenerateTextController` on a worker. The worker doesn't care who enqueues it, and a rake task or retry path makes this false.
- **What the caller has already done.** `# ...which has already authorized the record the context names` — the worst of the three, because it is a *contract assertion about code elsewhere* that goes on reading as authoritative after it stops being true. Real case: that line outlived the controller's `authorize` call by three commits. If the requirement is real, state it where it has to be *satisfied* ("this must be scoped to the user"), never as a claim that someone upstream already did.
- **Who else does this too.** `# smooth to the eye, same as Ai::Agents::ChatWorker`. A sibling cross-reference teaches nothing and rots on its own schedule.
- **What a page or feature does with this.** `# What the deal page's status dropdown shows`, `# the Apex deal whose planner the OS deal page reads`. A page, tab, or UI feature is code in another file, and naming it in product words doesn't make it any less so — describing a method by what its consumer does with the result is "who calls this" in disguise, and it goes stale the same way when that page changes. Say what the method returns and why, not who displays it.

The test: would this comment still be true if every other file in the repo were rewritten? If not, cut the part that reaches outside. Naming a collaborator *this code itself calls* is fine — that isn't across a boundary, it's on the line in front of you.

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

Test the exception before taking it: would the comment still be true with every guard and early return removed? If it only makes sense beside one of them, it is about that line, however much it sounds like it describes the method. Real miss: `# Setting a status the deal already has would still run what moving to it does, such as activating a voucher.` sat above `def write_status` and read like a note on writing a status, but it explained the one `return … if status == current_status` that skips the write. It belonged on that `return`.

**Why something is called goes at the call; what a method does goes on the method.** A reason for making a call - why this branch takes it, why it runs here, why it runs at all - belongs on the call, and most of all inside a conditional, where the reader is working out which branch they're in and why. A comment on the `def` explains the method itself: what it returns, or a non-obvious why inside its own body. The tell is a method comment that only makes sense next to its caller: one that opens with "Otherwise", "So", or "Because", or that reads as a reason to take a branch. That comment is answering a question the call site asks. Real case: why a rep deal or a lease space skips the property writers sat on `attach_documents` and `refuse_property_values`, where it read as unexplained; it belonged on the `else` that calls them. Naming the callee in such a comment is fine - it's on the line in front of you.

The same goes one level up: a class or module header says what the thing is for, in a sentence or two, and nothing more. Its details — a mode that fills blanks rather than replacing, a case it refuses, a guard it applies — go on the method or line that does them. A header that gathers every rule in the file is a second copy of them, kept far from the code, and it goes stale the first time one of those lines changes. Real case: a four-line header on `WriteVoucherFiguresFromIngest` restated the fill-or-replace rule, the commission-mode guard, the validity check, and the transaction-sides refusal; two of those already had comments on their own methods, and the guard's wording was wrong.

### Blank lines around a comment mid-block
A comment on a line (or a few related lines) in the middle of a block gets a blank line above the comment and one below the code it explains. That makes the comment stand out and shows how far it reaches - the reader can see it belongs to that code and not to what follows. Skip the blank line where the block already marks the edge: right after `def`/`do`/`if`, or right before `end`/`else`/`rescue`.

```ruby
# bad
add_halt_reply(response) if outcome == "halted"
# Every later turn replays the history, and providers reject an assistant message with no content.
ai_chat_messages.destroy(@message) if self.class.empty_reply?(response)
finish_metrics_turn(turn, outcome:)

# good
add_halt_reply(response) if outcome == "halted"

# Every later turn replays the history, and providers reject an assistant message with no content.
ai_chat_messages.destroy(@message) if self.class.empty_reply?(response)

finish_metrics_turn(turn, outcome:)
```

### Explain a concept where it lives
A comment explaining what a domain concept *is* — "In Buildout OS a deal is a Project; its stages and vouchers live on the Apex deals beneath it" — belongs on the model or module that owns the concept, or in the commit message. Not on a helper that merely uses it. The explanation can be true, non-obvious, and well written and still be in the wrong file.

The test: would someone looking for this explanation open this file? If not, it will never be found, and it rots unseen when the concept changes. On a helper, keep only the why of the helper's own lines.

### Comments are for the reader, not the reviewer
A comment answers "why is this code like this?" for someone who never saw any other version of it.
It does not answer "why did I write it this way rather than the other way?" — that belongs in the
commit message, where it stops being read once the debate it settles is over.

Two shapes, both banned:

- **Defending the design.** "A variant is a different list rather than different assembly, which is
  why these are methods and not classes of their own." This argues with an alternative the reader
  never proposed, and it reads as defensive the moment that alternative is forgotten. If the
  rejected approach matters, it matters in the commit or the PR.
- **Explaining an absence.** `# No tools block of its own`, on a class that has no tools block. The
  code says this by not being there, and the comment becomes a lie the day someone adds one. Same
  for "no validation here" or "deliberately no early return".

The test: would this sentence mean anything to someone opening the file for the first time, with no
memory of what it replaced? If it only makes sense beside a diff, it goes in the diff.

Length is the tell. A six-line header over a ten-line module is almost always this — the explanation
outgrew the code because it stopped describing the code.

### Comment voice — plain technical English, the way Mike writes
Write comments the way Mike does: direct, plain, and in the words engineers already use. His rewrites of
comments drafted for him show the style:

```ruby
# Many voucher values are stored as both an amount and a percent, with a unit flag indicating
# which one is the source of truth. And some values are derived from others - for example,
# percentage internal commissions are calculated from the total gross less deductions, etc.
#
# Use this after changing a voucher's values to set (not persist) the ones derived from them.

# Avoid using this directly - see DeriveVoucherValues instead

# A commission on a plan is updated by the voucher itself on save
```

- **Standard technical terms over figures of speech.** "Calculated", "derived", "source of truth", "persist" —
  not "worked out", "taken from", "comes out of", or "shares out".
- **Never "X names Y"** for one thing referring to another ("its payload names the review", "the id names a
  deal"). Say what it actually holds or does: "stores the review's id", "references", "points to", "is the id
  of". This applies to PR descriptions and commit messages as much as comments.
- **Conversational is fine.** A dash, a short parenthetical like "(not persist)", even an "etc." — and the
  passive voice where it reads naturally.
- **Imperative when telling the reader what to do:** "Avoid using this directly - see X instead".
- **Don't polish.** One or two plain sentences beat a carefully balanced one with stacked clauses. Formal or
  literary phrasing, and controlled-language styles such as ASD-STE100, are not his voice.

### Say "user", never "broker"
In comments, call the person using the app the **user**. Not every user is a broker — the same
screens are used by analysts, admins, marketing staff, and assistants — so "the broker has already
written" is wrong for most of the people it describes, and it quietly encodes an assumption about
who the software is for.

```ruby
# bad
# What the broker has typed into the form but not saved.
# good
# What the user has typed into the form but not saved.
```

This is about comments. Prompt text and user-facing copy are a separate question — ask rather than
assume, since a prompt describing a CRE listing may well have its own reason to name a role.

### Say "whitelist", not "allowlist"
For a list of what's permitted, use "whitelist" (and "blacklist" for the opposite) - in identifiers, comments, docs,
and commit messages. It's the more common word in this codebase, so it's the one people grep for.

```ruby
# bad
COLUMN_ALLOWLIST = { ... }
# good
WHITELIST_BY_TABLE = { ... }
```

### TODO format — `TODO: BSD-<number> -`
A TODO or FIXME doesn't need a ticket - `TODO: what to do` is fine. When one does have a ticket, write it as
`TODO: BSD-38678 - what to do`, in any language, not `TODO(BSD-38678):`.

```ruby
# bad
# TODO(BSD-38678): 2.x rebuilds those, so this is only needed when none of the files are readable.
# good
# TODO: BSD-38678 - 2.x rebuilds those, so this is only needed when none of the files are readable.
```

### No column alignment
Never pad tokens into visual columns across lines (routes `to:`, hash values, `=` in assignments, trailing comments). Single space, let lines be ragged. Alignment creates blast radius — the next longer token forces re-padding every line (noisy diff) or the block goes ragged anyway. `get "user_account", to: "user_accounts#show"`, not `get  "user_account",  to: ...`.

### Line length — the linter's limit is the ceiling, not a target
The linter owns "too long" (120 here, in both eslint `max-len` and rubocop). Everything under that is judgement, and it differs by what the line is:

- **Imports** — never split for width. Let them run to the limit; a wrapped import is noise.
- **Code** — a 119-character line is fine when it reads as one thought. Split when the split *names* the parts (a call with several arguments, a chain of steps), not because the line is merely close to the limit.
- **Comments** — use the width available. Wrapping prose at 80 or 100 out of habit costs extra lines and reflows the whole block when one word changes.

Don't reflow existing lines to use more width — this is about lines you're writing anyway (see "Minimal diffs").

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

### Names should say what kind of thing they are
A name carries the only type information a reader gets — Ruby and vanilla JS won't correct them, and
the mistake surfaces at the call site, far from the definition. So the name has to rule out the
readings it isn't.

A boolean is the usual casualty. `deposits` reads as a collection of deposits; as a flag meaning
"create deposits too" it misleads every caller until someone opens the method body. Prefix it —
`with_`, `has_`, `include_` — or make it a predicate.

```ruby
# bad - reads as an array of deposits
def perform(import_id, deposits = false)

# good - reads as the flag it is
def perform(import_id, with_deposits = false)
```

The same trap in the other direction: don't name a collection like a flag. `with_brokers` for a list
of brokers is as wrong as `brokers` for "include brokers". Applies to parameters, locals, struct
members, and hash keys alike.

A domain word on its own has the same problem when the domain has several measures of it. `gross` —
gross what, amount or percent? Say `gross_amount`. And where a figure belongs to one side of a deal,
name the side: `split_amount` could be the house's or the broker's, so call it `broker_split_amount`
when that's what it is. The suffix is the type, the prefix is the subject, and dropping either leaves
the reader guessing.

Two more shapes of the same mistake, both easy to write without noticing:

- **An adjective with no noun.** `stale = find_stale_workers` — stale what? The adjective says which
  ones, not what they are. Name the thing it describes: `stale_workers`.
- **An object's name on a number.** `worker = loads.index(loads.min)` reads as a worker, but it is an
  integer that picks a slot, a database, and a log file. Say what kind of value it is:
  `worker_number` (or `worker_index`, `worker_id`), matching whatever else calls it that
  (`TEST_ENV_NUMBER` here).

```ruby
# bad - an adjective, and an object's name on an integer
stale = find_stale_workers
worker = loads.index(loads.min)

# good
stale_workers = find_stale_workers
worker_number = loads.index(loads.min)
```

### Use the codebase's words — never coin new ones
When a concept already has a name — in the code, the schema, or the product — use it, even when it's long.
Don't introduce a synonym because it's shorter or reads better in prose. A coined word makes every reader map
it back to the real one, and someone who greps for it finds nothing.

Real cases from one branch: "share" for a commission, "pool" for the gross commission available to it
(`availableGrossCommission` in the form it was ported from), "price" for `transaction_value`, "the house's
share" for the house split, "unplanned" for a split with no plan. Each read fine in isolation and each was
wrong.

This holds for identifiers, comments, spec names, and commit messages alike. If a word collides with one the
code already uses for something else — "basis flag" where the code calls the flag a unit and uses "basis" for
what a percent is taken of — use the code's term.

### Method naming — verby for arg-takers, nouns for getters
Methods and functions that compute or take arguments get **verby** names (`get_`/`build_`/`fetch_` in Ruby, `get*`/`build*` in JS). Argumentless getters stay nouns.

- Arg-taking / computing → `get_collection_path(company)`, `build_url(...)`, `fetch_api(account)`, `getToolGroups(toolCalls)`.
- Argumentless getter → noun: `def api; ...; end`, attr readers.
- **Ruby:** `get_`/`set_` are fine. `Naming/AccessorMethodName` only flags *argumentless* `get_x` (and one-arg `set_x`); `get_foo(arg)` is not flagged and the codebase has ~500 `def get_*`. Don't rename `get_foo(arg)` to dodge a cop that isn't firing.

Mike corrected renames of `get_api`/`get_path` into `api_for`/`collection_path` — don't noun-ify arg-taking methods. JS is the same rule under a different spelling: alongside `getToolGroups` and `getQueuedCalls`, a bare `claimedActionIds(toolCalls)` should have been `getClaimedActionIds`.

Past-participle names are the same mistake in disguise: a spec helper named `serialized(*actions)` reads as a value, when it *serializes* them. `serialize` is better; **`serialize_actions` is best** — name the verb *and* what it acts on. Applies to spec helpers as much as app code.

Name what the method actually changes. A method that works out a commission's amount and percent is
`derive_commission_values`, not `derive_commissions` — it doesn't derive the commission, and the shorter name
says it does. Same for `update_split_values` over `update_split`, and `derive_house_deduction_values` over
`take_house_deductions`.

### Oxford commas
Use them when writing — prose, comments, commit messages, docs, PR descriptions. "the driver, the judge, and the report", not "the driver, the judge and the report".

### Use the app's defined date formats
Format a date with a format the app already defines - in Rails, the named formats in
`config/initializers/time_formats.rb` (`date.to_fs(:standard)`, `:us_short`, `:natural`) - not a new `strftime` string. A
hand-written `"%-m/%-d/%Y"` is a format the rest of the app doesn't use, and it drifts from the ones it does. Check the
existing formats before writing one; add a new named format only when none fits, and add it there rather than inline.

```ruby
# bad
"notice by #{notice_date.strftime("%-m/%-d/%Y")}"
# good
"notice by #{notice_date.to_fs(:standard)}"
```

### Don't extract single-use constants
This is about constants **internal** to a class or file — a value the code beside it uses. A constant that's part of the class's public API is a different thing; see the last exception below.

A value referenced once can just sit inline. Extracting it names it twice and sends the reader somewhere else to find out what it is, for no reuse in return. This goes double when the thing is **hard to name accurately** — if the best name available is a restatement of the value (`SPOKEN = %w[assistant]`, `DEFAULT_LIMIT = 20` next to the only `limit:` in the file), the constant is worse than the literal.

**Count references in the code, not executions.** One call site is single-use, however many times it runs. A map looked up once per row, per request, or per item of a loop is still single-use; "it's reused on every row" is not reuse.

**Size and shape don't exempt it.** A multi-entry lookup hash, a regex, a list of column prefixes, or a frozen array used once all go inline:

- a lookup hash read in one place becomes a `case` in that method (`TRANSACTION_SIDES_BY_SOURCE_KEY[value]` → a `case value` with a `when "BUYER", "TENANT"` branch)
- a regex goes at the one `match` that uses it
- a table driving one loop becomes the explicit calls it drives (`CONTACT_COLUMNS_BY_ROLE.filter_map { … }` → a literal list of `build_contact(row, :buyer, "Buyer", …)` calls)

**A comment doesn't earn the constant.** If the value needs explaining, the explanation moves to the line that uses it, along with the value.

Extract only when one of these holds:

- **Real reuse** — two or more references in the code.
- **A genuine contract** — something *else* depends on the value staying fixed: a route, an enum value, a wire key, a persisted string. A column header or label in a file we merely read is not a contract; read it as a literal where it's used.
- **The name teaches something the literal and the code around it can't** (`MAX_BYTES = 20.megabytes` earns its place; `HEADER = "Step"`, `OFFICE_COLUMN = "Office"`, or `X_BY_SOURCE_KEY` does not — a name that just says "this maps the source's values" restates the hash).
- **It's part of the class's public API** — a value the class offers for other code to read, and the class is its natural home. A worker's `CRON`, registered by the Sidekiq initializer, is fine with one reference: the schedule belongs to the worker, and keeping it there puts the reason for it in the same file. The test is whether you'd document it as something the class exposes, not whether it's used outside today.

Before keeping any constant, count its references. Same reasoning applies to extracting a method or a local for a single trivial use — see "Method order" and js-prefs on helpers.

### Method order — important first, then call order
Order a file by importance first, then by call order within it. The entry point comes first. Below it goes the main work — the methods that do what the file is for — and below that the methods that support it: guards, lookups, error messages, formatting. Within each of those, follow call order depth-first: a method's own callees sit right below it, before its next sibling, and a method with several callers sits under the first one. A callee never goes above its caller. Small utilities used throughout the file (money formatting, a `close?` comparison) go at the very bottom. Add a new method within the group it belongs to rather than at the top. In JS this needs no ceremony because function declarations hoist — see js-prefs "Helpers go below their caller, not above" for the JS specifics, including preferring `function` over a `const` arrow when hoisting is what makes the order possible.

Importance can override call order between groups, never within one. Real case: `Ai::Tools::EditDeal#execute` runs its guards (`get_target_error`, `get_request_error`, `get_text_failure`) before it edits, but the two edit methods sit right under `execute` and the guards below them — the edits are what the tool is for; the guards only decide whether it gets that far.

**This can be checked, so check it.** The rule exists to rule out arbitrary order. List the `def`s in file order beside the entry point's calls: each method should sit in its group (main work, support, utilities) and, within the group, under its first caller and in call order. Flag any method that fits neither — above its caller, or far from it with unrelated methods in between. Real miss: a 580-line one-off was audited as "roughly follows call order", and its `snapshot_royalties` was 300 lines from its only caller.

**Edge cases go last.** The main path comes first; a special case the file also handles — a rarely used
mode, an optional variant such as a voucher's transaction sides — goes at the bottom, after everything the main
path uses, even where strict call order would put it higher. It is not the first thing a reader cares about, so
it shouldn't be the first thing they read. Same within a method: one guarded call (`derive_side_values(…) if
sides.any?`) rather than the variant's body inline above the main path.

Don't reorder untouched code just to comply, and a file counts as untouched once its work is committed.

### Spec order — the main case first, details below
Order examples the way you order methods: the reader meets what the thing is *for* before its edge cases. The first `it` in a block is the core use case ("proposes an email"), and the narrower details — a flag that changes one field, an error path, an authorization refusal, a gate that omits something — sit below it.

Add a new example at the **bottom** of its block, not the top, for the same reason a new method goes below existing ones. Setup a block needs (`let`s, a small `def`) still goes above the examples it serves; that is setup, not an example.

### Unix-philosophy methods
A method should do one thing well. Favor small, single-purpose, side-effect-free functions over methods that both compute *and* mutate/orchestrate. When a method computes a value and applies it, prefer splitting — return the computed value and let the caller own the side effect. Lean toward more, smaller methods.

### No assignment inside conditionals
Assign on its own line, then test the variable. `if (outside = find(entry))` puts two things on one line, and a reader skimming the condition can mistake it for `==`. The wrapping parens only make it look intentional. Applies to `if`, `unless`, `elsif`, `while`, and ternaries, in any language.

```ruby
# bad
if (outside = source.match_outside_brokerage(entry))
  build_outside_commission(outside)
end

# good
outside = source.match_outside_brokerage(entry)
if outside
  build_outside_commission(outside)
end
```

### Port the behavior, not the source's quirks
When porting logic from another language or system — a JS form, an external service — port what it does, in
the target's idioms, not how it happens to do it. Don't reproduce its float handling, rounding modes,
intermediate object shapes, or flags that exist only because of its constraints. In Ruby that means BigDecimal
on the records themselves, not Floats in hashes shaped like the JS objects.

Don't build a parity harness (shared fixtures run by both test suites, CI path filters to trigger it) unless
asked. Ordinary specs of the behavior are enough for logic that rarely changes.

### Change the data rather than add a flag that overrides it
If a flag exists only to make code ignore what a record says — `in_dollars: true` overriding each record's own
unit — change the record so it says what's true, and drop the flag. Comment on the line that makes the change,
since that's the non-obvious step.

### Stay on the change's purpose
Don't widen a change to raise a metric — an eval pass rate, a lint count — or to fix things adjacent to the
task. When a run turns up problems outside the change's purpose, report them as findings and leave the fixes
for separate work. A fix that is in scope but distinct gets its own commit.

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

### Install dependencies without asking
Running `yarn install` or `bundle install` is always fine. When a tool fails on a missing or stale package, a lockfile changed underneath, or a spec won't load its dependencies, run the install and carry on — don't stop to ask or hand it back as a blocker. If the install alone doesn't fix it (a stale nested copy yarn won't prune, say), removing and reinstalling that one package under `node_modules` is fine too. This covers installing what the lockfile already says; adding, upgrading, or removing a dependency is still a change to ask about.

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

### Commits — logical chunks, each self-contained
Structure a branch as atomic commits, each one logical chunk of work that stands on its own: it carries its own tests, they pass at that commit, and in theory it could go to production in order without the commits after it. That's a guide for structure, not a deploy plan - what it buys is that each commit reviews on its own.

Passing at each commit is a best effort judged from the split, not something to verify. Don't run specs commit by commit (no `rebase --exec`, no checking out each one) - run them once at the tip. An intermediate commit that turns out not to pass is acceptable.

Cut commits by what the work is, not by which files it touched. The same file changing in several commits is normal, and partial commits are encouraged - stage hunks with `git add -p`, or commit an intermediate state of a file that a later commit changes again (a condition the first commit keeps strict and a later one relaxes, say). Don't bundle an unrelated piece into a commit just to avoid touching its file twice; that is what makes a commit hard to review. A refactor a later commit needs is its own commit, ahead of it.

No follow-up commits. When review turns up a bug in something an earlier commit on the branch introduced, fold the fix into that commit (see "Rebasing and force-pushing a `mike/` branch") rather than adding a fix on top.

### Commit messages — a subject line, usually nothing more
Format: `BSD-12345: Capitalized subject`. Most commits need only that. A body that says what the code does repeats the diff, and one that restates a comment repeats the code - both are noise. Add a body only when it carries something neither the diff nor the comments can, and expect that to be rare.

No `Co-Authored-By` trailer. Attribution is off in Mike's settings; don't copy one from other commits in the log.

### Rebasing and force-pushing a `mike/` branch
On a branch whose name starts with `mike/`, rewriting history is pre-approved — rebase, amend, autosquash, and `git push --force-with-lease` without stopping to ask, even when the commit is already on origin. It's his branch; nobody else builds on it. Don't raise "this is already pushed" as a blocker there.

This is not permission to commit unprompted — "Never stage or commit for Mike" still holds. It only removes the *extra* confirmation for rewriting history once he has asked for a fold, squash, amend, or reorder.

Anywhere else (`master`, a shared branch, someone else's `name/` branch), the old caution applies: say that the commit is published and let him decide.

Mechanics that avoid the unsupported interactive flags:

```
git add <files>
git commit --fixup <sha>
git rebase --autosquash --autostash <sha>~1
```

`--autosquash` works without `-i` on git ≥ 2.38, and `--autostash` keeps unrelated working-tree changes (a hunk deliberately held back for a later commit) out of the way and restores them after. Record `git log --oneline -4` first so the pre-rebase SHAs are recoverable.

### Routing "remember this" requests
When Mike asks you to remember a preference, **first evaluate whether it belongs in this skill** rather than as a standalone memory file:

- Reusable style / workflow rule that should shape how code is generated → add it here as a new `###` section under the right `##` group. Confirm the group before writing.
- Genuine project/codebase fact or external reference (a quirk of the repo, a URL, a behavioral gotcha) → keep it as a memory file as usual.

When in doubt, ask Mike which destination he wants.

### Never stage or commit for Mike
Do **not** run `git add`/`git commit` on Mike's behalf — not even when a unit of work is finished, tested, and lint-clean. Leave the working tree unstaged; just tell him what's ready and let him stage and commit himself. This holds regardless of the surrounding workflow (per-model, per-feature, etc.); "test → commit" rhythms mean *he* stages and commits, not you. Only stage/commit if he explicitly asks you to in that moment.

### Branch names — no Jira number up front
Name a new branch `mike/<short-description>`, e.g. `mike/resend-phone-code`, not `mike/BSD-38889-resend-phone-code`. The ticket number goes in commit messages (`BSD-38889: …`), not at the front of the branch name. Don't rename existing branches to comply.

## Ruby / Rails

Applies to `.rb`, on top of General.

Personal style defaults for any `.rb` edit, creation, or refactor in this repo. Not absolute — if Mike waives a rule for a one-off, honor it and note which rule was waived. Don't rewrite pre-existing code that violates these just because you touched the file (see general-prefs: minimal diffs); apply during genuine cleanup of code you're already changing, at most flag the rest.

### Hash & kwarg shorthand (Ruby 3.1+)
When the key and an in-scope variable/method share a name, use the bare-colon form:

- `{ user:, login_credential: }` not `{ user: user, login_credential: login_credential }`
- `Ai::Function.call(name, args, login_credential:, user:)` not `(..., login_credential: login_credential)`
- `new(foo:, bar:)` not `new(foo: foo, bar: bar)`

Only fall back to longhand when the value isn't an identically-named identifier (`{ user: current_user }`, `foo(name: record.name)`). The linter rewrites longhand on save — match it up front.

### Guards & indentation
- **Guard clauses only for longer bodies.** A guard (`return unless ...`, `next if ...`) protecting one or two lines reads worse than wrapping the body in a normal `if`. Trust rubocop — it flags when a guard would actually be preferable for the block size. Good: `do_thing if a && b && c` or an `if ... end` block.
- **`unless` takes one condition, and never a negated one.** The rule is about removing negations,
  not about avoiding `unless`. Two parts:

  **A compound condition never goes behind `unless`.** `unless a && b` or `unless a || b` makes the
  reader negate each part and recombine them before they know what the code does. Rewrite with `if`
  and the positive form.

  **A single condition takes whichever keyword avoids a `!`.** `unless x` reads better than
  `if !x` — reach for `unless` there rather than negating inside an `if`. And when the predicate
  itself is the negative one, swap the predicate instead of the keyword: `if x.present?`, not
  `unless x.blank?`. Same for `any?` over negating `all?`.

```ruby
# bad - compound condition behind a negation
unless !x || !y
  do_x
end

# good
if x && y
  do_x
end

# bad - negation inside an if
if !x
  do_x
end

# good
unless x
  do_x
end

# bad - negated predicate
if x.blank?
  do_x
end

# good - say it positively
if x.present?
  do_x
end
```

A guard clause is fine where it's otherwise justified, and follows the same rule:
`return false unless pending?`, not `return false if !pending?`. A guard whose condition is
genuinely compound keeps `if`: `return false if reverting? || reverted?`.

- **Prefer the positive condition to a negated skip.** This applies inside blocks as much as methods. A `next if`/`return unless` on a negated predicate makes the reader invert it and then scan for what survives; the positive form says what is kept, on the line that keeps it. Reach for `any?`/`present?` rather than negating `all?`/`blank?`.

```ruby
# bad — invert the predicate, then find the body it guards
lines.filter_map do |line|
  next if line.all?(&:blank?)

  headers.zip(line).to_h
end

# good — the condition names what is kept
lines.filter_map do |line|
  headers.zip(line).to_h if line.any?(&:present?)
end
```

  When the body is more than one expression, wrap it in `if ... end` rather than keeping the negated skip — same rule, just the block form.
- **Always 2-space indent.** Never align continuation lines to an operator, opening paren, or previous token. Prefer one-liners when reasonable, else 2-space continuation.

**One line is the preference.** Keep the call on one line whenever it fits; splitting is what you do
when it doesn't. When you must split, break after the opening paren and indent 2 spaces — never
half-wrap with the trailing arguments aligned under the first one.

**Once a hash or keyword list is split, give every member its own line.** Positional arguments are
not held to that: they can share a line, with the keyword arguments one per line after them.

```ruby
# good - fits on one line
Models::Payment.new(date: receivable[:date], gross_amount: gross.to_s)

# bad - split with variable indentation
Models::Payment.new(date: receivable[:date],
                    gross_amount: gross.to_s,
                    split_amount: split_amount.to_s)

# good - split with consistent indentation, one member per line for hashes
Models::Payment.new(
  date: receivable[:date],
  gross_amount: gross.to_s,
  split_amount: split_amount.to_s
)

# also good - non-hash args need not be one per line
Models::Whatever.new(
  receivable[:date], gross.to_s, split_amount.to_s,
  more: positional,
  hash: things
)
```

Alignment has the same blast radius as column alignment (see general-prefs): the next longer token forces re-indenting every line below it.

### `case`/`when` — body on its own indented line
Never use the one-line `when X then Y` form. Put the branch body on the next line, indented, even
when it fits on one line and even when every branch is a single call. A one-liner reads fine until
one branch grows or a `when` gets a longer condition, and then the block goes half-and-half; the
uniform shape also keeps the diff to one added pair of lines when a branch is added.

```ruby
# bad
case parent_type
when "Backoffice::Contact" then Backoffice::Ai::ContactContext.call(contact: parent, user:)
when "Apex::Deal" then Apex::Ai::DealContext.call(deal: parent, user:)
else {}
end

# good
case parent_type
when "Backoffice::Contact"
  Backoffice::Ai::ContactContext.call(contact: parent, user:)
when "Apex::Deal"
  Apex::Ai::DealContext.call(deal: parent, user:)
else
  {}
end
```

`else` follows the same rule. Applies to new code and to branches you add to an existing statement;
don't reformat an untouched `when` block just because you added one to it.

### `filter` over `select`
Prefer `filter` to its alias `select` for Enumerable filtering (`collection.filter { |x| ... }`). Same for `filter_map`. Don't rewrite existing `select` calls on untouched lines, and don't flag `select` in review — this is only the default when writing new code.

### `|| 0` for nil defaults, not a conversion
When a nullable number needs a default, write `value || 0`. Don't use `.to_d`, `.to_i`, or `.to_f` as a nil
guard: it reads as a type conversion and hides the intent, and on a decimal column the value is already a
BigDecimal.

### Call constructors with their keywords
Don't write a helper that only turns positional arguments into a constructor's keywords
(`build_value(record, :amount, :percent, **flags)` for `Value.new(record:, amount_attribute:, …)`). Calling the
constructor directly names each field at the call site, which is worth the extra lines.

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
When a schema tweak is needed and the migration that introduced the table/column is **unmerged** (created on this feature branch, not yet on master), edit that migration in place — don't `rails generate` a new incremental migration. Only add a new migration when the original is already merged/released. Editing an already-run migration needs `db:rollback` + `db:migrate` (or `db:migrate:redo`) to take effect on an existing dev DB, and that is also what regenerates `db/schema.rb` (see below).

### Never hand-edit `db/schema.rb`
`db/schema.rb` is output, not source. Change it only by running the migration (`bin/rails db:migrate`, or `db:migrate:redo` for an amended one) and letting Rails dump it, then use the `stage-schema` skill to keep just this branch's changes out of the churn. Never write table definitions, indexes, or the version line into it by hand — not to avoid touching the dev DB, not to save a step, not because the migration "obviously" produces a given block.

A hand-written block is a guess at what the database will produce: charset, collation, column order, and defaults are all things MySQL decides, and a copied-from-a-neighbor guess can be wrong without looking wrong. The next real `db:migrate` then rewrites it, and the difference lands in someone else's diff.

### Simple interactors are class methods
An interactor that just takes its inputs and does one job is a class method. Don't write the `def self.call` → `new(...).call` → `def initialize` → `def call` dance with `attr_reader`s, which is four definitions to carry the arguments one hop. Define the methods inside `class << self`, pass helpers what they need as arguments, and hide them under a plain `private` in that block, not with `private_class_method`.

```ruby
# bad - an instance with no state worth keeping
class Enroll
  def self.call(user:, address:)
    new(user:, address:).call
  end

  def initialize(user:, address:)
    @user = user
    @address = address
  end

  def call
    release_inaccessible_claim
    # ...
  end

  private

  attr_reader :user, :address
end

# bad - class methods, but hidden one by one
class Enroll
  def self.call(user:, address:)
    release_inaccessible_claim(user:, address:)
    # ...
  end

  def self.release_inaccessible_claim(user:, address:)
    # ...
  end
  private_class_method :release_inaccessible_claim
end

# good
class Enroll
  class << self
    def call(user:, address:)
      release_inaccessible_claim(user:, address:)
      # ...
    end

    private

    def release_inaccessible_claim(user:, address:)
      # ...
    end
  end
end
```

An instance is fine when there's real state to hold: many inputs threaded through many helpers, memoized lookups, or values built up across steps. Don't convert existing instance-style interactors just because you touched them.

**One `.call`, with a keyword for a variant.** When an interactor serves a variant of its input, take an
optional keyword — `call(voucher, side: nil)` — rather than parallel entry points (`for_voucher` / `for_side`)
or making callers compose `call(build_subset(voucher))`. The builders and any structs they make stay private
(`private_constant` for the structs). Put a large piece of such an interactor in a separate interactor file with
its own spec, not a class nested inside it.

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

Within each block, the order is whatever vim `:sort` (whole-line) produces — which puts default imports before named ones, since `{` sorts after every letter.

Where a new import goes depends on the block it lands in:

- **Block already in sort order** → insert at its sorted position, which is where a re-sort would put it. `Button` belongs between `Badge` and `Card`, not tacked on the end.
- **Block not in sort order** (plenty are) → append at the end. Don't re-sort the block to make room; that's a bulk reorder of untouched lines.

Either way a named import never lands among the defaults — `{` sorts last, so the named group starts after the final default and a new `{ … }` import stays inside it. Apply to imports you add or change; don't bulk-reorder untouched files.

### No `../..` in import paths
A single `../` is fine. Two or more stops describing where the module lives and starts counting directories — the reader has to walk the tree to find out what it points at, and it silently means something else the moment either file moves. Use the full path from the project root instead.

```ts
// bad
import { useConversationContext } from '../../conversation_context';
import type { Message } from '../../types';
// good
import { useConversationContext } from 'components/ai/assistant/conversation_context';
import type { Message } from 'components/ai/assistant/types';
```

Both forms are Internal, so this never moves an import to a different block — only its sorted position within one.

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

### Jest is for units, not React rendering
Jest earns its place on the things a unit test is actually good at: redux actions and reducers, custom hooks, helpers, pure functions. React rendering is not one of them.

Never mount a component to assert what a user would see — copy on a button or a label, whether a control is disabled, where a link points, which element showed up. That is noise: it reddens on wording and markup changes that break nothing, and it never exercised the real page anyway. Coverage of that kind belongs in a Playwright spec under `e2e/playwright/`, or nowhere. See also "Don't assert on non-load-bearing strings", which this is the rendering-shaped case of.

A new `mount(...)` in a Jest spec is the tell — enzyme is almost always the wrong tool reached for. Existing enzyme specs stay put (don't churn them), but don't add to them, and don't write one to cover a component you just built.

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

### A value computed once is a variable, not a function
When a component renders a value that depends on a few cases, compute it into a variable during render. Don't wrap the branching in an inner function that the JSX calls once. A single-use function named like a noun (`description()`) reads as a value but makes the reader go find its body to learn that it is one. Early returns are no reason to extract it.

Never use a nested ternary for this. Use `let` with an `if` / `else if` / `else` chain, so each case sits on its own line.

```tsx
// bad — a one-use function standing in for a value
function description() {
  if (!codeExpiresAt) {
    return `Sent to ${number}.`;
  }
  …
}
<Field.Description>{description()}</Field.Description>

// bad — nested ternary
const description = !codeExpiresAt ? `Sent to ${number}.` : expired ? … : …;

// good
let description: string;
if (!codeExpiresAt) {
  description = `Sent to ${number}.`;
} else if (new Date(codeExpiresAt) <= new Date()) {
  description = `The code sent to ${number} has expired.`;
} else {
  description = `Sent to ${number}. It expires at ${formatTime(codeExpiresAt)}.`;
}
<Field.Description>{description}</Field.Description>
```

A single, flat ternary is still fine. A function earns its place when it is called from more than one spot, or when it takes arguments. Don't convert existing ones in untouched code.
