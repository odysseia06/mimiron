# Authoring guide

How to add new skills, agents, hooks, and templates to Mimiron.

## Adding a new skill

### 1. Create the skill directory

```
skills/<skill-name>/
├── SKILL.md
├── templates/      (optional)
│   └── ...
└── examples/       (optional)
    └── ...
```

### 2. Write the SKILL.md

Every skill is a Markdown file with YAML frontmatter:

```yaml
---
name: <skill-name>
description: <one-line description of what the skill does>
argument-hint: "<usage hint shown to users>"
disable-model-invocation: true    # recommended for agent-backed skills
context: fork                     # isolate from parent conversation
agent: <agent-name>               # which agent handles this skill
allowed-tools: <comma-separated list>
model: sonnet                     # or another supported model
---

<Instructions for the agent>
```

Key fields:
- **name** — must match the directory name
- **description** — clear, actionable summary
- **allowed-tools** — explicit list; use `Bash(<prefix> *)` patterns to scope Bash access
- **agent** — references an agent file in `agents/`
- **context: fork** — recommended to isolate agent context

### 3. Add supporting files

Templates go in `skills/<skill-name>/templates/`. Reference them from the skill instructions.

Examples go in `skills/<skill-name>/examples/`. These are especially useful for defining output formats.

### 4. Register in plugin.json

Add an entry to the `skills` array in `plugin.json`:

```json
{
  "path": "skills/<skill-name>/SKILL.md",
  "name": "<skill-name>",
  "description": "<description>"
}
```

### 5. Add a smoke test

Create `tests/smoke/test_<skill-name>_structure.sh` that validates:
- SKILL.md exists and has valid frontmatter
- Referenced templates and examples exist
- Referenced agent exists

### 6. Update CHANGELOG.md

Add the new skill under `[Unreleased]`.

## Adding a new agent

### 1. Create the agent file

```
agents/<agent-name>.md
```

### 2. Write the agent definition

```yaml
---
name: <agent-name>
description: <what this agent does>
tools: <comma-separated tool list>
model: sonnet
permissionMode: acceptEdits
maxTurns: 30
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./.claude/scripts/<guard-script>.py"
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            <validation prompt>
---

<Agent instructions>
```

### 3. Permission mode guidance

| Mode | When to use |
|---|---|
| `default` | Interactive use where user confirms each action |
| `acceptEdits` | Automated workflows where file edits are expected |
| `acceptAll` | Avoid unless you have strong justification |

Default to `acceptEdits` for automated agents.

### 4. Hook configuration

**PreToolUse hooks** — guard scripts that run before each tool invocation. Use these to enforce safety rules.

**Stop hooks** — validation that runs when the agent wants to finish. Use these to ensure completeness.

The hook `command` path should be relative to the project root (`./.claude/scripts/...`) for manual installs, or use plugin-relative paths for plugin installs.

### 5. Register in plugin.json

Add an entry to the `agents` array.

## Adding a guard script

### 1. Create the script

```
scripts/<script-name>.py
```

### 2. Follow the hook protocol

Guard scripts for PreToolUse hooks must:
- Read JSON from stdin
- Check `hook_event_name` and `tool_name`
- Output a JSON deny decision to stdout if blocking
- Exit 0 with no output to allow

```python
#!/usr/bin/env python3
import json
import sys

def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # fail open

    if payload.get("hook_event_name") != "PreToolUse":
        sys.exit(0)
    if payload.get("tool_name") != "Bash":
        sys.exit(0)

    command = (payload.get("tool_input") or {}).get("command", "")

    # Your deny logic here
    # deny("Reason for blocking")

    sys.exit(0)  # allow

if __name__ == "__main__":
    main()
```

### 3. Make it executable

```bash
chmod +x scripts/<script-name>.py
```

### 4. Standard library only

Guard scripts must use only Python standard library modules. No `pip install` dependencies.

### 5. Register in plugin.json

Add an entry to the `scripts` array.

## Adding hooks safely

Hooks are powerful — they can block or modify tool invocations. Follow these guidelines:

1. **Scope narrowly** — match only the tools and patterns you need to guard
2. **Fail open for availability** — if the hook script crashes, let the tool proceed rather than breaking the session
3. **Fail closed for safety** — if a command matches a dangerous pattern, deny it
4. **Log nothing sensitive** — hook output should not contain credentials, tokens, or PII
5. **Test thoroughly** — hook bugs can silently block legitimate commands
6. **Document the deny reasons** — when a hook denies a command, the reason should be clear and actionable

## Adding templates and examples

Templates and examples are plain Markdown files. They live under the relevant skill directory:

```
skills/<skill-name>/templates/<template>.md
skills/<skill-name>/examples/<example>.md
```

Reference them from the skill's SKILL.md instructions using relative paths. The agent will read them at runtime.

## Checklist for new contributions

- [ ] Asset file created in the correct directory
- [ ] YAML frontmatter is valid
- [ ] Registered in `plugin.json`
- [ ] Smoke test added
- [ ] CHANGELOG.md updated
- [ ] Security implications considered (see [security-model.md](security-model.md))
- [ ] No new external dependencies introduced
