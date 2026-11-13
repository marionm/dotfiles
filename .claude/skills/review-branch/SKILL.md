---
name: review-branch
description: Do a code review of the changes on current branch
allowed-tools: Bash, Read, Glob, Skill
---

Compare the current state of git against the merge-base with the remote's default branch, so commits that landed on it after the branch was cut - or that a stale local `master` is missing - don't show up as part of the change:

```
git fetch --quiet origin
base=$(git merge-base HEAD "$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/master)")
git diff "$base"
git log --oneline "$base"..HEAD
```

Do not separate staged/unstaged/committed diffs — `git diff "$base"` shows everything in one shot.

If the user specifies a different base branch or commit hash, use the merge-base with that instead.

Run the review by invoking the built-in `code-review` skill, telling it to review this local branch diff against that base. Forward the effort level the user passed ($ARGUMENTS, e.g. low/medium/high/max).

This is a local review only. Never post to a PR, never run `gh pr comment`, and do not pass `--comment` — report findings here in the conversation.
