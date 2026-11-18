---
name: cleanup
description: Audit changed code against Mike's prefs (~/.claude/skills/prefs/SKILL.md) by fanning out one prefs-audit agent per file, then report the violations. Use when Mike asks to clean up, check, or audit changes against his preferences - or says /cleanup. Takes an optional scope - paths, a git ref or range, or a .diff file - and defaults to what this session has written.
---

# /cleanup

Audit changed code against Mike's prefs and report what breaks them. On-demand: nothing runs this
automatically, so it is worth running before handing work back, after a large refactor, or whenever
Mike asks.

## 1. Resolve the scope

`$ARGUMENTS` decides what gets audited. Take the first form that matches:

| Argument | Scope |
|---|---|
| *(none)* | what this session wrote — see below |
| one or more paths / globs | those files, diffed against the session baseline (or `HEAD`) |
| a git ref or range (`master`, `HEAD~3`, `abc123..def456`) | `git diff <that>`, every file it touches |
| `branch` | everything this branch changed against its base — see below |
| a path ending `.diff` or `.patch` | that file's contents, as-is |

**The base branch is not always `master`.** Resolve it, don't assume it:

```
git symbolic-ref --quiet --short refs/remotes/origin/HEAD    # e.g. origin/master
git rev-parse --verify --quiet origin/main                    # fall back
```

Prefer whichever of those exists, then `git merge-base HEAD <base>`. If Mike named a base, his wins.

**Default scope** comes from the two bookkeeping hooks:

- `~/.claude/state/prefs-review/$SESSION.written` — absolute paths written this session, one per
  line. `$SESSION` is this session's id.
- `~/.claude/state/prefs-review/$SESSION.base` — the commit HEAD sat at when the session began.
  Missing means the session predates the hook; fall back to `HEAD`.

Take the written paths, keep the ones inside the current repo, and drop any whose own diff against
the base is empty — the marker records paths a *command mentioned*, so echoed examples and files
merely read land there too. If nothing survives, say so and stop; there is nothing to audit.

## 2. Fan out

One `prefs-audit` agent per file, launched together in a single message so they run concurrently.
Each gets exactly:

```
Diff command: git -C <repo> diff <base> -- <the one file>
Prefs skills: ~/.claude/skills/prefs/SKILL.md
```

For a `.diff`/`.patch` argument, split it per file and pass `sed -n '/^diff --git .*<file>/,/^diff --git /p' <the file>` instead — or, if splitting is awkward, pass the whole file to a single agent.

Per-file beats one agent over everything: measured on a 10-file Ruby diff, ten agents took 146s and
found six violations where one agent took 247s and found one. Attention thins out when a single
agent holds ten diffs against thirty-odd rules.

**Above ~12 files, group rather than fan out further** — keep an implementation with its spec, a
model with its serializer. Related files in one agent is the seam that costs nothing; splitting a
file from its spec is the seam that hides cross-file rules.

## 3. Check commit messages

Only when the scope covers commits — the `branch` form or a ref range. `prefs-audit` only sees diffs,
so read the messages yourself while the agents run:

```
git log --format='%h %s%n%b' <base>..HEAD
```

Check each against the prefs' **Commit messages** rule, and report each miss with its SHA and a
suggested message. Rewording a commit rewrites history, so don't amend or rebase for it now — list it in
the **When asked to fold** block, and apply it when Mike asks to fold.

## 4. Adjudicate, then report

The agents cannot edit — `prefs-audit` has no write tools, by design. Everything below is yours to
do: you adjudicate, and you apply. Their findings are claims, and two agents can disagree with
each other — in one run, one flagged `rescue => e` as a single-letter local while another cleared it
after grepping up 449 precedents against 14. Reconcile before reporting rather than passing both on.

Drop a finding when it sits on a line the branch didn't add, when the rule's own prose carves out an
exception the agent missed, or when a second agent cleared the same construct with better evidence.

Then apply what survives — this skill cleans up, it does not hand back a list of chores. Report to
Mike **only** the violations and the fixes; never the clean verdicts, never the per-rule walk. If
nothing survives, one line saying so is the whole report.

## 5. Leave every fix unstaged

No `git add`, no commit, and no rebase, even for fixes to staged or committed code. Mike reads the
fixes as an unstaged diff and stages them himself.

For a fix to a line committed on this branch, note the commit it belongs to: `git blame` the line it
corrects (for a pure addition, the line beside it), and record the target SHA per hunk, not per file
— one file's fixes can belong to two commits.

If any fix has a target commit, or a commit message needs rewording, end the report with a **When asked to
fold** block, listing each target commit with its files and hunks, and its new message if it gets one. Do
nothing with it until Mike asks. When he does: `git add -p` the hunks for one target, `git commit --fixup
<sha>`, repeat per target, then `git rebase --autosquash --autostash <oldest target>~1` - and apply the
new messages in the same rebase.
