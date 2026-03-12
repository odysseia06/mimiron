# Usage

## solve-issue workflow

The primary workflow in Mimiron is the `solve-issue` skill, which automates implementing GitHub issues.

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

Any text after the issue number is passed as optional guidance to the implementing agent.

### What happens under the hood

1. The `solve-issue` skill spawns the `issue-implementer` agent in a forked context
2. The agent operates with `acceptEdits` permission mode — it can read and write files, but Bash commands are mediated
3. Every Bash command passes through `guard_bash_commands.py`, which blocks:
   - Pushes to main/master/trunk
   - Force-push
   - `git reset --hard`
   - `rm -rf /` and `rm -rf .git`
   - `git clean -fdx`
   - `gh pr merge` and `gh issue close`
4. When the agent thinks it's done, the Stop hook validates the response for completeness and honesty
5. The final response follows a structured format with a machine-readable trailer

### Output format

The skill returns a structured report:

```
## Implemented
- Added input validation to the /api/users endpoint

## Validation
- `npm test` — passed
- `npm run lint` — passed

## Git
- Issue: #42
- Branch: `issue/42-add-user-input-validation`
- Commit: `abc1234`
- Pushed: yes

## Follow-up comment
Posted: no
none

## Remaining risks or future improvements
- none

## Machine-readable trailer
ISSUE_NUMBER: 42
BRANCH: issue/42-add-user-input-validation
COMMIT_SHA: abc1234
PUSHED: yes
VALIDATION_RUN: yes
FOLLOWUP_COMMENT_POSTED: no
LEFTOVERS_PRESENT: no
```

### When to use this workflow

Good fits:
- Bug fixes with clear reproduction steps
- Small feature additions with well-defined scope
- Dependency updates
- Documentation fixes
- Test additions

Less ideal fits:
- Large architectural changes (break into smaller issues first)
- Issues that require extensive discussion or design decisions
- Changes that need manual testing or visual review

### Prerequisites

The workflow requires:
- `gh` CLI installed and authenticated
- A git repository with a remote named `origin`
- Permission to push branches to the remote
- A clean working tree (no uncommitted changes)

### Comment policy

The agent only posts a comment to the issue when there is something materially useful to share:
- Known trade-offs or limitations in the implementation
- Leftovers that need follow-up
- Credible next-step extensions

It does not post "I'm done!" noise.

### Safety boundaries

The workflow will not:
- Push to the default branch
- Force-push any branch
- Close the issue
- Merge any PR
- Execute destructive git or filesystem commands
- Claim success for operations that failed

If something goes wrong (auth failure, test failure, push rejection), the agent reports it honestly in the structured output.
