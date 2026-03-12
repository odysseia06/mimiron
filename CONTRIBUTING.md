# Contributing to Mimiron

## Getting started

```bash
git clone https://github.com/odysseia06/mimiron.git
cd mimiron
```

No build step required. Mimiron is plain Markdown, Python (stdlib only), and shell scripts.

## Repository structure

| Directory | Agent family | Status |
|---|---|---|
| `.claude/` | Claude Code | Active — fully implemented |
| `.agents/` | Codex | Placeholder — skill skeletons only |

See [docs/architecture.md](docs/architecture.md) for the full layout.

## Local development

```bash
# Test Claude plugin locally
bash install/install.sh --target /path/to/test-project --scope project --mode symlink

# Run smoke tests
bash tests/smoke/test_structure.sh
python3 tests/smoke/test_guard_script.py

# Verify structure
bash install/verify.sh --source .
bash install/verify-codex.sh --source .
```

## What to contribute

### Claude Code (`.claude/`)

New skills, agents, guard scripts, bug fixes, docs. See [docs/authoring-guide.md](docs/authoring-guide.md).

### Codex (`.agents/`)

Currently placeholders. When contributing:
- **Do not** copy Claude instructions into Codex skills
- Author natively using Codex conventions
- Keep `allow_implicit_invocation: false` until skills are tested

### General

Tests, install script improvements, CI improvements, documentation.

## Coding standards

- **Python**: 3.8+, stdlib only, executable, shebang
- **Shell**: bash 3.2+, `set -euo pipefail`, quote expansions
- **PowerShell**: 5.1+, strict mode
- **Markdown**: YAML frontmatter for skills and agents

## Security-sensitive changes

PRs touching Bash access, hook scripts, permission modes, git push, or gh commands require extra review. See [docs/security-model.md](docs/security-model.md).

## Pull request process

1. Fork and branch from `main`
2. Make changes
3. Run smoke tests
4. Update `CHANGELOG.md`
5. Open PR using the template

## Code of conduct

[Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
