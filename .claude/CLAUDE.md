# Global instructions (Mike)

## Code style

Defined in the prefs skill and imported here so they load with this file rather than depending on a
hook - CLAUDE.md survives compaction, injected context does not. The skill stays the only copy.

@~/.claude/skills/prefs/SKILL.md

## Routing "remember this" requests

When I ask you to remember a preference, **first evaluate whether it belongs in my `prefs` skill** (`~/.claude/skills/prefs/SKILL.md`) rather than as a standalone memory file:

- Reusable style / workflow rule that should shape how code is generated → add it to `prefs` as a new `###` section under the right `##` group (General / Ruby / JS). Confirm the group before writing. Never restate a prefs rule as a memory file - the skill is the only place they are defined.
- Genuine project/codebase fact or external reference (a quirk of a repo, a URL, a behavioral gotcha) → keep it as a memory file as usual.

When in doubt, ask which destination I want.
