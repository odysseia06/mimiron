# Usage

## Claude Code: solve-issue workflow

The primary workflow in Mimiron is the `solve-issue` skill for Claude Code. It automates implementing GitHub issues.

Codex skills are scaffolded but not yet authored — this page covers the Claude implementation only.

### Basic usage

```
/solve-issue 42
```

This will:
1. Read issue #42 using `gh issue view`
2. Check that the working tree is clean
3. Create a feature branch `issue/42-<short-description>`
4. Implement the fix
5. Run validation (tests, linting, build — whatever the repo supports)
6. Commit with a message referencing the issue
7. Push the branch to origin
8. Optionally comment on the issue if there are meaningful leftovers

### With guidance

```
/solve-issue 42 focus on the API layer, the frontend change can wait
```

### What happens under the hood

1. The `solve-issue` skill spawns the `issue-implementer` agent in a forked context
2. The agent operates with `acceptEdits` permission mode
3. Every Bash command passes through `guard_bash_commands.py`, which blocks pushes to main, force-push, destructive commands, `gh pr merge`, and `gh issue close`
4. The Stop hook validates the response for completeness and honesty
5. The final response follows a structured format with a machine-readable trailer

### Prerequisites

- `gh` CLI installed and authenticated
- A git repository with a remote named `origin`
- Permission to push branches to the remote
- A clean working tree

### Safety boundaries

The workflow will not:
- Push to the default branch
- Force-push any branch
- Close the issue or merge any PR
- Execute destructive git or filesystem commands
- Claim success for operations that failed

These guardrails are enforced by Claude Code's allowed-tools restriction and the PreToolUse guard script. They are Claude-specific — Codex does not have equivalent enforcement yet.
