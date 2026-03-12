# Authoring guide

How to add new skills, agents, hooks, and templates to Mimiron. Claude and Codex have separate authoring flows.

## Claude Code

### Adding a skill

1. Create `.claude/skills/<skill-name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: <skill-name>
description: "<one-line description>"
argument-hint: "<usage hint>"
disable-model-invocation: true
context: fork
agent: <agent-name>
allowed-tools: <comma-separated list>
model: claude-opus-4-6
---

<Instructions for the agent>
```

2. Add supporting files under `templates/` and `examples/` within the skill directory.
3. Register in `plugin.json`.
4. Add a smoke test.
5. Update `CHANGELOG.md`.

### Adding an agent

1. Create `.claude/agents/<agent-name>.md` with YAML frontmatter.
2. Default to `permissionMode: acceptEdits` for automated agents.
3. Register in `plugin.json`.

### Adding a guard script

1. Create `.claude/scripts/<script-name>.py`.
2. Follow the PreToolUse hook protocol: read JSON from stdin, output deny decision or exit silently.
3. `chmod +x`. Standard library Python only.
4. Register in `plugin.json`.

## Codex

Codex skills live under `.agents/skills/`. Currently all are placeholders.

When authoring:
- Use Codex-native conventions
- **Do not** copy Claude instructions, hooks, or permission concepts into Codex skills
- Keep `allow_implicit_invocation: false` in `.agents/openai.yaml` until skills are fully tested

## Checklist

- [ ] Asset created in correct directory (`.claude/` or `.agents/`)
- [ ] Valid YAML frontmatter
- [ ] Registered in `plugin.json` (Claude only)
- [ ] Smoke test added
- [ ] CHANGELOG.md updated
- [ ] Security implications considered
