# Mimiron

Reusable skills, subagents, hooks, and automation for Claude Code.

Mimiron is an extension pack designed for evelopers who want production-grade Claude Code workflows without building everything from scratch.

## What's included

| Asset | Description |
|---|---|
| **solve-issue** skill | Read a GitHub issue, implement the fix on a feature branch, validate, commit, push, and optionally comment back. |
| **issue-implementer** agent | Focused subagent that does the actual implementation work with guardrails. |
| **guard_bash_commands.py** | PreToolUse hook that blocks dangerous bash commands (force-push, pushes to default branch, destructive operations). |

## Quickstart

### Plugin install

Install Mimiron as a Claude Code plugin:

```bash
# Project-level
claude plugin add github:mimiron-dev/mimiron

# User-level
claude plugin add --scope user github:mimiron-dev/mimiron
```

Then use it:

```
/solve-issue 42
/solve-issue 42 focus on the validation layer, skip UI changes
```

### Manual install

For environments where the plugin system is not available:

```bash
# Clone and install to a project
git clone https://github.com/mimiron-dev/mimiron.git
cd mimiron
bash install/install.sh --target /path/to/your/project --scope project
```

See [docs/installation.md](docs/installation.md) for all options including user-level install, symlink mode, and dry-run.

## Documentation

- [Architecture](docs/architecture.md) — why plugin-first, repo layout rationale
- [Installation](docs/installation.md) — all install paths and options
- [Usage](docs/usage.md) — how to use the solve-issue workflow
- [Security model](docs/security-model.md) — threat model, guardrails, review guidance
- [Authoring guide](docs/authoring-guide.md) — how to add new skills, agents, hooks
- [Release process](docs/release-process.md) — versioning, changelog, publishing

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding standards, and PR process.

## Security

See [SECURITY.md](SECURITY.md) for the security policy, responsible disclosure process, and threat model overview.

## License

[MIT](LICENSE)
