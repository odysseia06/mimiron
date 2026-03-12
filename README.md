# Mimiron

A multi-agent skills and automation repository. Reusable skills, subagents, hooks, and workflow automation for AI coding agents.

Mimiron provides parallel implementation surfaces for different agent families. Each agent runtime gets its own directory, conventions, and install path.

| Agent family | Directory | Status |
|---|---|---|
| Claude Code | `.claude/` | Active — skills, agents, and hooks fully implemented |
| Codex | `.agents/` | Placeholder — skill skeletons scaffolded, not yet authored |

## What's included

### Claude Code (active)

| Asset | Description |
|---|---|
| **solve-issue** skill | Read a GitHub issue, implement the fix on a feature branch, validate, commit, push, and optionally comment back. |
| **issue-implementer** agent | Focused subagent that does the implementation work with guardrails. |
| **guard_bash_commands.py** | PreToolUse hook that blocks dangerous bash commands. |

### Codex (placeholder)

| Asset | Description |
|---|---|
| **solve-issue** skill stub | Minimal placeholder — not yet functional. |

## Quickstart

### Claude Code — plugin install (recommended)

```bash
# Project-level (recommended for teams)
claude plugin add github:odysseia06/mimiron

# User-level
claude plugin add --scope user github:odysseia06/mimiron
```

Then use it:

```
/solve-issue 42
/solve-issue 42 focus on the validation layer, skip UI changes
```

### Claude Code — manual install

```bash
git clone https://github.com/odysseia06/mimiron.git
cd mimiron
bash install/install.sh --target /path/to/your/project --scope project
```

### Codex — manual install

```bash
bash install/install-codex.sh --target /path/to/your/project
```

Note: Codex skills are placeholders only and are not yet functional.

See [docs/installation.md](docs/installation.md) for all options including user-level install, symlink mode, and dry-run.

## Design principles

- **Multi-agent** — parallel implementation surfaces for different agent runtimes
- **Least privilege** — no broad auto-approvals; guard scripts block dangerous commands by default
- **Team-ready** — project-level install is the default scope
- **Reversible** — installers create backups, record manifests, and uninstall restores previous state
- **Auditable** — all behavior is in readable Markdown and Python; no compiled artifacts
- **Minimal dependencies** — standard library Python, bash, and PowerShell only

## Documentation

- [Architecture](docs/architecture.md) — repo layout, multi-agent design rationale
- [Installation](docs/installation.md) — Claude and Codex install paths
- [Usage](docs/usage.md) — how to use the solve-issue workflow
- [Security model](docs/security-model.md) — threat model, guardrails, agent-specific controls
- [Authoring guide](docs/authoring-guide.md) — how to add skills for Claude or Codex
- [Release process](docs/release-process.md) — versioning, changelog, publishing

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding standards, and PR process.

## Security

See [SECURITY.md](SECURITY.md) for the security policy, responsible disclosure process, and threat model overview.

## License

[MIT](LICENSE)
