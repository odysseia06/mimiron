# Contributing to Mimiron

Thank you for considering a contribution. This document covers how to set up, develop, test, and submit changes.

## Getting started

```bash
git clone https://github.com/mimiron-dev/mimiron.git
cd mimiron
```

No build step is required. Mimiron is plain Markdown, Python (stdlib only), and shell scripts.

## Local development

### Test the plugin locally

```bash
# Install to a test project in symlink mode
bash install/install.sh --target /path/to/test-project --scope project --mode symlink --dry-run

# If the dry-run looks correct, run for real
bash install/install.sh --target /path/to/test-project --scope project --mode symlink
```

### Run smoke tests

```bash
bash tests/smoke/test_structure.sh
python3 tests/smoke/test_guard_script.py
```

### Verify structure

```bash
bash install/verify.sh --source .
```

## What to contribute

We welcome:

- **New skills** — reusable Claude Code skills that follow the patterns in `skills/`
- **New agents** — subagent definitions that follow the patterns in `agents/`
- **Guard/hook scripts** — safety scripts that enforce workflow guardrails
- **Bug fixes** — in existing skills, agents, or scripts
- **Documentation** — corrections, clarifications, new guides
- **Test coverage** — smoke tests, fixture-based tests, edge case coverage

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter
2. Add any supporting files under `skills/<skill-name>/templates/` and `skills/<skill-name>/examples/`
3. Register the skill in `plugin.json`
4. Add a smoke test in `tests/smoke/`
5. Update `CHANGELOG.md`
6. See [docs/authoring-guide.md](docs/authoring-guide.md) for the full guide

## Adding a new agent

1. Create `agents/<agent-name>.md` with YAML frontmatter
2. Register the agent in `plugin.json`
3. If the agent uses hook scripts, add them under `scripts/` and document the path expectations
4. Add a smoke test
5. Update `CHANGELOG.md`

## Coding standards

### Markdown
- Use YAML frontmatter for all skill and agent files
- Keep lines readable (no strict wrap limit, but avoid excessively long lines)

### Python
- Python 3.8+ compatible
- Standard library only — no third-party dependencies
- Use `json.dumps` for structured output, not `print` with string concatenation
- All scripts must be executable (`chmod +x`)
- Include a `#!/usr/bin/env python3` shebang

### Shell
- POSIX-compatible bash (bash 3.2+)
- Use `set -euo pipefail` at the top of scripts
- Quote all variable expansions
- Use `[[ ]]` for conditionals
- Avoid bashisms that break on older systems when practical

### PowerShell
- PowerShell 5.1+ compatible
- Use `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`

## Security-sensitive changes

Any PR that touches the following areas requires extra scrutiny:

- **Bash tool access** — changes to allowed-tools lists in skills or agents
- **Hook scripts** — changes to guard_bash_commands.py or new hook scripts
- **Permission modes** — changes to agent permissionMode settings
- **Git operations** — anything that could push, force-push, reset, or delete
- **GitHub CLI operations** — anything that could close issues, merge PRs, or modify repo settings

See [docs/security-model.md](docs/security-model.md) for the full threat model.

## Pull request process

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run smoke tests locally
4. Update `CHANGELOG.md` under `[Unreleased]`
5. Open a PR with a clear title and description using the PR template
6. Address review feedback

## Commit messages

Use clear, imperative-mood commit messages:

```
Add solve-issue skill for GitHub issue automation
Fix guard script false positive on gh issue view
Update installation docs for Windows PowerShell
```

Reference issue numbers when applicable: `Fix #42: handle missing default branch`.

## Code of conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.
