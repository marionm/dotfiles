---
name: review-branch
description: Do a code review of the changes on current branch
allowed-tools: Bash, Read, Glob, Skill
---

Compare the current state of git vs the local `master` branch using `git diff master` and `git log master..HEAD --oneline`. Do not separate staged/unstaged/committed diffs — `git diff master` shows everything in one shot.

If the user specifies a different base branch or commit hash, use that instead of `master`.

Run the review by invoking the built-in `code-review` skill, telling it to review this local branch diff against that base. Forward the effort level the user passed ($ARGUMENTS, e.g. low/medium/high/max).

This is a local review only. Never post to a PR, never run `gh pr comment`, and do not pass `--comment` — report findings here in the conversation.
