# Mimiron — Repository agent guide

Mimiron is a multi-agent skills and automation repository. It provides parallel implementations for different AI coding agents.

## Repository layout

| Directory | Agent family | Status |
|---|---|---|
| `.claude/` | Claude Code | Active — skills, agents, and hooks are fully implemented |
| `.agents/` | Codex | Placeholder — skill skeletons exist but are not yet authored |

## Claude Code assets (`.claude/`)

Fully implemented. Contains:

- `skills/solve-issue/` — end-to-end GitHub issue implementation skill
- `agents/issue-implementer.md` — focused subagent with guardrails
- `scripts/guard_bash_commands.py` — PreToolUse hook blocking dangerous commands

Claude-specific concepts (allowed-tools, permissionMode, PreToolUse/Stop hooks) apply only here.

## Codex assets (`.agents/`)

Placeholder only. The `skills/solve-issue/` directory contains a minimal stub. It is **not functional** and should not be invoked. `openai.yaml` has `allow_implicit_invocation: false` to prevent accidental use.

Codex skills will be authored in a future phase.

## Contributing

- Claude assets: edit files under `.claude/` following `docs/authoring-guide.md`
- Codex assets: these are placeholders — do not port Claude instructions into them without a dedicated authoring pass
- See `CONTRIBUTING.md` for full guidance
