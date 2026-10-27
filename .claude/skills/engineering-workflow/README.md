# Engineering Workflow Skill

This is an initial Claude Code skill encoding the evidence-first collaboration workflow and is meant to be reusable across projects. It was derived from real work, for example a full-stack assignment and the Gravity Flip game, which are examples of the workflow, not dependencies.

## Install for your user account

Copy the `engineering-workflow` folder to:

- **Windows:** `%USERPROFILE%\.claude\skills\engineering-workflow\`
- **WSL/Linux:** `~/.claude/skills/engineering-workflow/`

Choose the location corresponding to the environment where you run Claude Code. If you use Claude Code separately in Windows and WSL, install it in the environment you actually use.

Then start/restart a Claude Code session if needed and invoke:

`/engineering-workflow`

You can also let Claude Code discover it when a task matches the description.

## Files

- `SKILL.md` — the skill instructions.

## Design note

This is a deliberately initial, single-file version. It encodes the shared workflow, not the domain-specific details of either project. After testing it on a few real tasks, refine it based on observed misses rather than adding complexity preemptively.
