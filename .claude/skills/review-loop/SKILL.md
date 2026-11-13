---
name: review-loop
description: Review this branch from three sides at once - Mike's prefs audit, a fresh-context reviewer, and the open PR's AI review if there is one - then triage every finding, fix the real ones, and leave the fixes unstaged with instructions for folding them into their commits when asked. Use when Mike says /review-loop, or when he has asked for it as part of a workflow, such as before each commit.
---

# /review-loop

Three independent reviews of the branch, one triage, and fixes left unstaged for Mike to read. The
triage is yours; Mike is the arbiter, and he judges it by reading the diff you leave behind.

## Never write to GitHub

This skill only **reads** from GitHub. No `git push`, no `gh pr create`, `gh pr comment`, or
`gh pr review`, no resolving or replying to threads, and no write-side `gh api` calls (anything with
`-X POST`/`PATCH`/`PUT`/`DELETE`, or a GraphQL `mutation`). Don't call the cubic MCP tools either —
`trigger_pr_review` and `update_pr_issue_status` both post to the PR. If there is no PR, there is no
PR review; never open one to get it.

## 1. Scope

The branch against its base, resolved the way `/cleanup`'s **Resolve the scope** section does for its
`branch` form. Diff the working tree against the merge-base — `git diff <merge-base>` — so a second
run sees fixes a first run left unstaged.

Write the reviewer's goal line now: one or two sentences on what the branch is meant to do, from the
conversation if it has one, otherwise from the commit subjects and their ticket number. Nothing about
how it was built.

Check for a record of an earlier run at `$(git rev-parse --absolute-git-dir)/review-loop/<branch>.md`
(the branch name with `/` replaced by `-`). If it exists, its rejected findings go to the reviewer in
step 3.

## 2. Start waiting on the PR

```
gh pr view --json number,headRefOid,url
```

No PR → skip this step and step 4.

With a PR, start the wait in the background (`run_in_background: true`) before anything else, since
it's the slow part. It exits 0 once cubic has reviewed the PR's head commit, or 1 after 15 minutes:

```
for attempt in $(seq 1 30); do
  gh api "repos/{owner}/{repo}/pulls/<number>/reviews" --jq 'any(.[]; .user.login == "cubic-dev-ai[bot]" and .commit_id == "<headRefOid>")' | grep -qx true && exit 0
  sleep 30
done
exit 1
```

If local `HEAD` isn't `headRefOid`, the PR review covers different code from the other two. Carry on,
and label its findings "reviewed at <short sha>" in the triage.

## 3. Run the local reviews

Launch these in one message so they run together.

**Prefs audit.** Fan out `prefs-audit` agents exactly as `/cleanup`'s **Fan out** section describes,
over the step 1 scope, and check the branch's commit messages as its **Check commit messages** section
describes. Don't invoke `/cleanup` itself — it applies its own fixes, and here its findings are claims
for step 5 like everyone else's. A commit-message finding's fix is a suggested message, never a
rewrite.

**Fresh reviewer.** One `Agent` call, `subagent_type: "general-purpose"`. **Never a fork** — a fork
inherits this session, which is the anchoring this review exists to avoid. Send:

> You are reviewing a change you did not write. You have no context on it beyond this message —
> that's deliberate. Read it cold.
>
> **What the change is meant to do:** `<the goal line from step 1>`
>
> **The change:** run these to see it.
> ```
> git --no-pager log --oneline <merge-base>..HEAD
> git --no-pager diff <merge-base>
> ```
>
> Commit messages are part of the evidence — if one claims something the diff doesn't do, that's a
> finding.
>
> Read the diff, then enough of the surrounding files to judge it in context — a hunk alone doesn't
> tell you whether the callers, the callbacks, or the other branches of that conditional still hold.
> Read the repo's CLAUDE.md and any nested one under a directory the diff touches; code that breaks
> one is a finding even when it works. Mike's personal style rules (`~/.claude/skills/prefs/SKILL.md`)
> are audited separately, so spend your attention on correctness and the repo's rules.
>
> **Do not modify any files, and do not run the specs, the test suite, or the linters.** Read the
> code and report only.
>
> Report findings ranked most severe first. For each: `file:line`, one sentence stating the defect,
> and a concrete failure scenario — the input or state that produces the wrong result. A finding you
> can't write a failure scenario for is a preference; drop it. A broken CLAUDE.md rule is the one
> exception — quote the rule and point at the line that breaks it.
>
> A test is a finding when it doesn't earn its place - one the branch adds, or an existing one the
> branch makes redundant. That's a test that repeats what another example already covers, tests the
> framework or a library rather than this code, or would still pass with the change it covers
> reverted. Name the example, and say what already covers it or why it can't fail.
>
> Out of scope: style opinions no CLAUDE.md rule covers, "consider extracting this", speculative
> abstraction, blanket requests for more tests, and praise. **If the change is sound, say so and
> report nothing.**
>
> `<only on a repeat run:>` These findings were raised on an earlier review and rejected, with the
> reason. Don't raise them again unless you think the reason is wrong — and then say why.
> `<the rejected findings and reasons from the step 1 record>`

## 4. Collect the PR review

Once the step 2 wait exits, pull every unresolved, non-outdated thread — any author, not only cubic.
A timeout isn't an error: cubic may have nothing to say, or not run at all. Collect what threads
exist and note the timeout in the report.

```
gh api graphql -F owner='{owner}' -F repo='{repo}' -F number=<number> -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes { isResolved isOutdated path line comments(first: 1) { nodes { author { login } body } } }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select((.isResolved | not) and (.isOutdated | not))'
```

cubic bodies open with HTML comments (`<!-- cubic:... -->`); skip past them to the finding.

## 5. Triage

Merge duplicates first — the three sources will often flag the same line. Triage each issue once and
note every source that raised it; agreement between sources is signal.

Then judge each against the actual code:

- **Fix** — it's real. A bug this branch introduces is in scope by definition.
- **Wrong** — the source misread the code or missed a caller. Name the file and line that proves it.
- **Out of scope** — real, but it predates the branch or belongs to another ticket. Say which.
- **Preference** — speculative abstraction, a wrapper nothing needs. A finding that quotes a
  CLAUDE.md or prefs rule is never this: either the code changes, or you name why the rule doesn't
  reach it.

Drop a prefs finding on a line the branch didn't add, or where the rule's own prose carves out the
exception. Don't re-raise anything the earlier-run record already settled.

## 6. Fix

Smallest diff that fixes the cause. **Leave every fix unstaged** — no `git add`, no commit, even for
fixes to committed code.

For each fix, note the commit it belongs to: `git blame` the line it corrects (for a pure addition,
the line beside it), and record the target SHA per hunk, not per file — one file's fixes can belong
to two commits.

Then lint the touched files and run the specs that cover them.

## 7. Record and report

Write the triage to the step 1 record path, replacing any earlier one: each finding, its sources,
verdict, and reason. That's what a repeat run reads.

Report to Mike:

1. A table — finding, sources, verdict, reason. Rejected findings stay in it with their one-line
   reason, so he can overrule one.
2. Lint and spec results.
3. Whether the PR review ran, timed out, or was skipped for having no PR, and the SHA it covered.
4. A closing **When asked to fold** block, listing each target commit with its files and hunks. Do
   nothing with it until Mike asks. When he does: `git add -p` the hunks for one target,
   `git commit --fixup <sha>`, repeat per target, then `git rebase --autosquash --autostash <oldest target>~1`.
