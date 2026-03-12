# Security model

Claude Code and Codex have fundamentally different safety mechanisms. This document separates them clearly.

## Principles

1. **Least privilege** — every component requests only the access it needs
2. **Defense in depth** — multiple layers prevent dangerous operations (Claude)
3. **Transparency** — all behavior is visible in readable source files
4. **Agent-specific controls** — security mechanisms are described per agent family, not globally

## Claude Code: defense layers

| Layer | Mechanism | What it does |
|---|---|---|
| 1 | Skill allowed-tools | Only listed tools/command prefixes available |
| 2 | Agent permissionMode | `acceptEdits` — Bash requires approval unless in allowed-tools |
| 3 | PreToolUse guard script | Denies force-push, default-branch push, destructive commands, out-of-scope gh commands |
| 4 | Stop hook | Validates response completeness and honesty |
| 5 | maxTurns: 30 | Prevents runaway execution |
| 6 | context: fork | Isolates agent conversation |

## Codex: current state

Codex skills are **placeholders only**. No functional implementation, no Codex-specific guardrails.

Codex does not have:
- `allowed-tools` restriction
- `permissionMode`
- `PreToolUse` or `Stop` hooks
- Guard script protocol

The Claude guardrails documented above **do not apply to Codex**.

## Threat model

### Addressed (Claude)

| Threat | Mitigation |
|---|---|
| Push to default branch | Guard script + allowed-tools |
| Force-push | Guard script |
| Destructive commands | Guard script |
| Close issues / merge PRs | Guard script |
| Infinite loop | maxTurns cap |
| False success claims | Stop hook |
| Prompt injection via issue body | Hard rules in skill definition |
| Malicious install overwrites | Backup + manifest tracking |

### Not addressed

| Threat | Reason |
|---|---|
| Compromised credentials | Not managed by Mimiron |
| Malicious model output | Runtime's responsibility |
| Branch protection bypass | Repo owner's responsibility |

### Known limitations

1. Regex-based guard can be bypassed by creative command construction
2. Agent reads issue bodies that could contain adversarial content
3. Agent can read any file in the project
4. Codex placeholders have no guardrails

## Review checklist

- [ ] allowed-tools not expanded without justification
- [ ] Guard patterns not weakened
- [ ] permissionMode not escalated
- [ ] No new push/force-push/delete commands
- [ ] No new gh commands modifying repo state
- [ ] Prompt injection risks considered
- [ ] Codex placeholders remain non-functional
