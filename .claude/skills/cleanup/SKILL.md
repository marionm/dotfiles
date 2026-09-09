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

## 3. Adjudicate, then report

The agents cannot edit — `prefs-audit` has no write tools, by design. Everything below is yours to
do: you adjudicate, you apply, you stage. Their findings are claims, and two agents can disagree with
each other — in one run, one flagged `rescue => e` as a single-letter local while another cleared it
after grepping up 449 precedents against 14. Reconcile before reporting rather than passing both on.

Drop a finding when it sits on a line the branch didn't add, when the rule's own prose carves out an
exception the agent missed, or when a second agent cleared the same construct with better evidence.

Then apply what survives — this skill cleans up, it does not hand back a list of chores. Report to
Mike **only** the violations and the fixes; never the clean verdicts, never the per-rule walk. If
nothing survives, one line saying so is the whole report.

## 4. Put each fix where its code already lives

Never commit, and never rebase. Where a fix lands depends on where the line it corrects came from —
check with `git blame -L <line>,<line> -- <file>`:

| the violated line is | leave the fix |
|---|---|
| unstaged | unstaged |
| staged | staged (`git add` it) |
| committed on this branch | staged |

Staging a fix to committed code leaves it sitting ready for Mike to fold into the right commit
himself — his history, his call. Don't `git commit --fixup`, don't `git rebase --autosquash`, and
don't write a cleanup commit.

A single file can hit more than one of these at once. Go by the line, not the file.
