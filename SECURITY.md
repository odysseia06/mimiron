# Security policy

## Reporting vulnerabilities

If you discover a security vulnerability in Mimiron, please report it responsibly.

**Do not open a public issue.** Instead, email the maintainers directly or use GitHub's private vulnerability reporting feature on the repository.

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation within 7 days for critical issues.

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | Yes |

## Scope

Mimiron distributes Claude Code skills, subagent definitions, and hook scripts. Security concerns include:

- **Unintended command execution** — skills and agents that invoke Bash, git, or gh commands
- **Permission escalation** — agent configurations that grant broader access than intended
- **Guard bypass** — weaknesses in hook scripts that allow blocked commands to execute
- **Supply chain** — compromised plugin distribution or tampered files

## Threat model overview

### What Mimiron controls

| Component | Risk surface | Mitigation |
|---|---|---|
| `solve-issue` skill | Invokes an agent with Bash, git, gh access | Scoped allowed-tools list; agent runs in fork context |
| `issue-implementer` agent | Executes Bash commands in the user's repo | PreToolUse guard script; `acceptEdits` permission mode; maxTurns cap |
| `guard_bash_commands.py` | Hook script that runs on every Bash tool call from the agent | Denies force-push, default-branch push, destructive commands, out-of-scope GitHub operations |
| Install scripts | Copy or symlink files into `.claude/` directories | Backup before overwrite; manifest tracking; dry-run support |

### What Mimiron does NOT control

- Claude Code's own permission and sandboxing model
- The user's git credentials, SSH keys, or GitHub tokens
- The target repository's branch protection rules
- Network access or filesystem permissions on the host

### Sensitive capabilities

The following capabilities are security-sensitive and require careful review in any contribution:

1. **Bash tool access** — any skill or agent that lists `Bash` or `Bash(...)` in allowed-tools can execute arbitrary shell commands within its scope
2. **git push** — pushing to a remote can modify shared repository state
3. **gh CLI** — GitHub CLI commands can create/modify issues, PRs, releases, and repo settings
4. **Hook scripts** — PreToolUse hooks can allow, deny, or modify tool invocations
5. **Permission modes** — agent permissionMode settings control what the agent can do without user confirmation
6. **MCP integrations** — future MCP-backed extensions could connect to external services

### Least-privilege defaults

Mimiron ships with these safety defaults:

- The guard script **blocks** force-push, pushes to main/master/trunk, `git reset --hard`, `rm -rf /`, `rm -rf .git`, `git clean -fdx`, `gh pr merge`, and `gh issue close`
- The agent uses `permissionMode: acceptEdits` (not `acceptAll`)
- The agent has `maxTurns: 30` to prevent runaway execution
- The skill runs in `context: fork` to isolate the conversation context
- The Stop hook validates that the agent produced a complete, honest response before allowing it to finish

## Review guidance for maintainers

### Checklist for security-sensitive PRs

When reviewing a PR that touches any of the sensitive areas above:

- [ ] Does the change expand the allowed-tools list? If so, is every new tool justified?
- [ ] Does the change modify or weaken the guard script's deny patterns?
- [ ] Does the change modify an agent's permissionMode? If so, why?
- [ ] Does the change add new Bash commands that are not covered by the guard?
- [ ] Does the change introduce any new git push, force-push, or branch deletion?
- [ ] Does the change add gh commands that modify repository state (merge, close, delete)?
- [ ] Does the change introduce file writes outside of the expected `.claude/` tree?
- [ ] Could the change be exploited by a malicious issue body (prompt injection via issue text)?
- [ ] Are there new hook scripts? Do they fail open or fail closed? Is that appropriate?
- [ ] Does the change maintain idempotency of install/uninstall scripts?

### Prompt injection awareness

The `solve-issue` skill reads GitHub issue bodies, which are user-controlled input. The agent should:

- Treat issue text as untrusted data for implementation guidance
- Not execute commands found in issue bodies verbatim
- Not follow instructions in issue text that contradict the skill's hard rules

Contributors adding new skills that consume external input should consider similar risks.

## Security-related configuration

Users can further restrict Mimiron by:

- Adding project-level `.claude/settings.json` with stricter permission defaults
- Configuring branch protection rules on their repositories
- Using GitHub's required reviewers and status checks
- Running Claude Code in restricted permission modes
