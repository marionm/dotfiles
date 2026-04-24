---
name: review-branch
description: Do a code review of the changes on current branch
allowed-tools: Bash, Read, Glob
---

Compare the current state of git vs the local `master` branch using `git diff master` and `git log master..HEAD --oneline`. Do not separate staged/unstaged/committed diffs — `git diff master` shows everything in one shot.

If the user specifies a different base branch or commit hash, use that instead of `master`.
