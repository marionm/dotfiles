---
name: stage-schema
description: Stage only the parts of db/schema.rb that correspond to migrations added on the current branch. Skips noise like MySQL 8 utf8mb3 charset flips, column reorderings, and stray changes from unmerged branches that were checked out previously. Run after `rails db:migrate` when schema.rb has churn beyond what this branch's migrations should produce.
allowed-tools: Bash, Read
---

# stage-schema

The goal is a clean staged `db/schema.rb` that reflects ONLY the schema effects of migrations introduced on the current branch, with all other churn (charset flips, column reorderings, extra tables/columns from other work) left as unstaged edits the user can review, discard, or handle separately.

## Procedure

1. **List branch-specific migrations.** Check all three of the following — an in-progress migration is very commonly untracked and not yet committed:
   ```
   git diff --name-only --diff-filter=A master -- db/migrate/   # added on branch vs master
   git diff --name-only master -- db/migrate/                    # includes modified migrations
   git ls-files --others --exclude-standard -- db/migrate/       # untracked (very common!)
   ```
   Union the three lists. If all three are empty, stop and tell the user there's nothing branch-specific to stage.

2. **Read each migration** (added, modified, or untracked) to enumerate the expected schema effects:
   - `add_column :table, :col, …` → a new `t.…` line inside `create_table "table"`.
   - `remove_column :table, :col` → removal of that `t.…` line.
   - `add_index` / `remove_index` → index lines inside the table block.
   - `create_table` / `drop_table` → whole `create_table "table" …` block added/removed.
   - `rename_column` / `rename_table` / `change_column` → paired removals and additions.
   - Custom SQL (`execute`, `reversible`) → ask the user what effect they expect before guessing.

   Also note the *latest* migration timestamp on this branch — that's the expected value for `ActiveRecord::Schema.define(version: …)` at the top of schema.rb.

3. **Read the current schema.rb diff:**
   ```
   git diff db/schema.rb
   ```
   Classify each hunk:
   - **keep**: matches an effect enumerated in step 2, OR is the version-line bump to the expected timestamp from step 2.
   - **skip**: everything else — charset/collation flips (`utf8` ↔ `utf8mb3`), column reorderings, tables/columns from migrations NOT on this branch, whitespace-only changes, etc.

4. **Stage only the "keep" hunks.** Preferred approach: build a filtered patch from `git diff db/schema.rb` containing only the keep hunks, then apply it to the index:
   ```
   git apply --cached <filtered.patch>
   ```
   If that fails (hunks depend on surrounding skipped context), fall back to: construct the desired staged schema.rb by starting from the committed version and editing in only the keep changes, then `git add` that file, then restore the original working-tree version with a copy back.

5. **Report** what was staged vs skipped. Brief summary by category (e.g. "staged: 1 new column `users.archived`; skipped: 523 utf8mb3 charset flips, reorder of `listings` columns, 1 column `deals.stray_id` not from any branch migration").

6. **Leave the working tree unchanged.** All non-matching changes must remain as unstaged edits so the user can `git checkout`, `git stash`, or investigate them on their own.

## Notes

- Default base is `master`. If the user names a different base, use that.
- If a migration uses `reversible` or raw `execute`, surface the migration content and ask which hunks to include rather than guessing.
- Safe to re-run: if the index already has partial staging, `git reset HEAD db/schema.rb` first to start clean.
- Escape hatch for the user: `git restore --staged db/schema.rb` unstages everything without touching the working tree.
