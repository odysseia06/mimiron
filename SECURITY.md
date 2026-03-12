# Security policy

## Reporting vulnerabilities

If you discover a security vulnerability in Mimiron, please report it responsibly.

**Do not open a public issue.** Instead, email the maintainers directly or use GitHub's private vulnerability reporting feature.

We will acknowledge receipt within 48 hours and aim to provide a fix within 7 days for critical issues.

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | Yes |

## Scope

Mimiron distributes skills, agent definitions, and hook scripts for multiple AI coding agent runtimes.

## Agent-specific security controls

### Claude Code

Multiple enforcement layers: allowed-tools, permissionMode, PreToolUse guard scripts, Stop hook validation, turn limits, fork context. See [docs/security-model.md](docs/security-model.md) for details.

### Codex

Codex skills are **placeholders only** with no functional implementation. Codex does not support the same hook or permission concepts as Claude Code. The Claude guardrails **do not apply to Codex**.

## Review checklist

- [ ] No new Bash tool access without justification
- [ ] Guard script deny patterns not weakened
- [ ] Agent permissionMode not escalated (Claude)
- [ ] No force-push, default-branch push, or destructive commands
- [ ] Prompt injection risks considered
- [ ] Codex placeholders remain non-functional
