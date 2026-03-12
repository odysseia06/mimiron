# Security model

This document describes Mimiron's security architecture, threat model, and review guidance.

## Principles

1. **Least privilege** — every component requests only the access it needs
2. **Defense in depth** — multiple layers prevent dangerous operations
3. **Fail closed for safety** — guard scripts deny by default for matched patterns
4. **Fail open for availability** — guard scripts do not break sessions on malformed input
5. **Transparency** — all behavior is visible in readable source files
6. **No hidden side effects** — every action the skill/agent takes is documented

## Defense layers

### Layer 1: Skill-level tool restrictions

The `solve-issue` skill declares an explicit `allowed-tools` list:

```
allowed-tools: Read, Grep, Glob, Edit, MultiEdit, Write,
  Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), ...
```

Only the listed tools and command prefixes are available to the agent. This is enforced by Claude Code itself.

### Layer 2: Agent permission mode

The `issue-implementer` agent uses `permissionMode: acceptEdits`, which means:
- File reads: allowed
- File edits/writes: allowed (user sees them)
- Bash commands: require approval unless covered by the allowed-tools list

This is more restrictive than `acceptAll` and less restrictive than the default interactive mode.

### Layer 3: PreToolUse guard script

Every Bash command the agent invokes passes through `guard_bash_commands.py` before execution. The guard denies:

| Pattern | Reason |
|---|---|
| `git push origin main/master/trunk` | Protect default branch |
| `git push origin HEAD:main/master/trunk` | Protect default branch |
| `git push --force` / `-f` / `--force-with-lease` | Prevent history rewriting |
| `git reset --hard` | Prevent data loss |
| `git clean -fdx` | Prevent data loss |
| `rm -rf /` | Prevent system destruction |
| `rm -rf .git` | Prevent repo destruction |
| `gh pr merge` | Out of scope for this workflow |
| `gh issue close` | Out of scope for this workflow |

The guard uses regex matching on normalized command strings. It is intentionally simple and auditable.

### Layer 4: Stop hook validation

When the agent attempts to finish, the Stop hook validates:
- The response contains all required machine-readable trailer fields
- The response does not claim success for operations that were not completed
- If leftovers are marked present, the response includes concrete details

This prevents the agent from silently failing or fabricating results.

### Layer 5: Agent turn limit

The agent has `maxTurns: 30`, preventing runaway execution loops.

### Layer 6: Fork context

The skill runs in `context: fork`, isolating the agent's conversation from the parent context.

## Threat model

### Threats addressed

| Threat | Mitigation |
|---|---|
| Agent pushes to default branch | Guard script denies; skill allowed-tools restricts to `Bash(git *)` only |
| Agent force-pushes and rewrites history | Guard script denies force-push patterns |
| Agent runs destructive commands | Guard script denies `reset --hard`, `clean -fdx`, `rm -rf /`, `rm -rf .git` |
| Agent closes issues or merges PRs | Guard script denies `gh pr merge` and `gh issue close` |
| Agent enters infinite loop | maxTurns: 30 cap |
| Agent claims false success | Stop hook validates response completeness and honesty signals |
| Prompt injection via issue body | Agent treats issue text as implementation guidance, not executable instructions; hard rules in skill definition override any issue content |
| Malicious install overwrites user files | Installer creates backups; manifest tracks exactly what was placed; uninstall restores |

### Threats NOT addressed (out of scope)

| Threat | Why out of scope |
|---|---|
| Compromised `gh` credentials | Mimiron does not manage authentication |
| Malicious Claude Code model output | Model safety is Claude's responsibility |
| Compromised Python runtime | Host security is the user's responsibility |
| Network-level attacks | Mimiron does not manage network security |
| Branch protection bypass | Repository-level settings are the repo owner's responsibility |

### Known limitations

1. **Regex-based guard** — The guard script uses regex pattern matching, which can be bypassed by sufficiently creative command construction (e.g., aliases, shell functions, encoded commands). It is a practical guardrail, not a security boundary.

2. **Issue body as input** — The agent reads issue bodies that could contain adversarial content. The skill's hard rules are the primary defense, but a sufficiently sophisticated prompt injection could potentially influence behavior.

3. **File system access** — The agent can read and write files within the project. It cannot be prevented from reading sensitive files (`.env`, credentials) that exist in the working tree.

## Review guidance

### For maintainers reviewing PRs

See the checklist in [SECURITY.md](../SECURITY.md).

### For users evaluating Mimiron

Before installing, consider:

1. **Do you trust the skill definitions?** Read `skills/solve-issue/SKILL.md` and `agents/issue-implementer.md` to understand exactly what tools the agent can use.

2. **Do you trust the guard script?** Read `scripts/guard_bash_commands.py` to see what is blocked and what is allowed.

3. **Are your repo protections adequate?** Branch protection rules, required reviews, and status checks are your server-side defense. Mimiron's guards are client-side convenience.

4. **Do you have sensitive files in your working tree?** The agent can read any file in the project. Use `.gitignore` and keep secrets out of the working tree.

## Recommended hardening

For high-security environments:

1. Use branch protection rules requiring PR reviews before merge
2. Use required status checks (CI must pass)
3. Keep credentials in environment variables or secret managers, not in files
4. Review the guard script and add additional patterns for your environment
5. Run Claude Code in a restricted permission mode
6. Audit the install manifest after installation
