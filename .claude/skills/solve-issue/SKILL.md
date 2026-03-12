---
name: solve-issue
description: "Read a GitHub issue, implement the fix on a feature branch, run validation, commit and push the work, and leave a concise issue follow-up comment only when there are meaningful leftovers or future extensions."
argument-hint: "[issue-number] [optional implementation notes]"
disable-model-invocation: true
context: fork
agent: issue-implementer
allowed-tools: Read, Grep, Glob, Edit, MultiEdit, Write, Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(pytest *), Bash(python -m pytest *), Bash(cargo *), Bash(dotnet *), Bash(go test *), Bash(mvn *), Bash(gradle *), Bash(just *), Bash(make *)
model: claude-opus-4-6
---

ultrathink before editing.

Supporting files for this skill:

- `templates/issue-followup-comment.md`
  - Use this only when there are real leftovers, trade-offs, or credible next extensions worth posting back to the GitHub issue.
- `examples/final-response-format.md`
  - Your final response to the parent conversation must follow this structure exactly.

Interpret the first token in `$ARGUMENTS` as the GitHub issue number.
Interpret any remaining text as optional user guidance.

## Your job

Complete the issue end-to-end:

1. Read the issue with GitHub CLI and understand the requested change.
2. Identify the repository default branch.
3. If the working tree is dirty with unrelated changes, stop and report that clearly instead of mixing work.
4. Create or switch to a dedicated feature branch named `issue/<number>-<short-kebab-slug>`.
5. Inspect the codebase and implement the smallest correct change that resolves the issue.
6. Add or update tests when the repo and the change warrant it.
7. Run the smallest meaningful validation command(s) for this repo.
8. Commit the work with a focused commit message that references the issue number.
9. Push the branch to `origin`.
10. Leave a GitHub issue comment only if there are meaningful leftovers, known trade-offs, or obvious next-step enhancements. Do not post noise.
11. Return the result exactly in the format shown in `examples/final-response-format.md`.

## Hard rules

- Never push directly to the default branch.
- Never use force-push for this workflow.
- Never close the issue or merge a PR as part of this workflow.
- Never claim tests or validation passed unless they actually ran successfully.
- Never claim push or comment success unless the command actually succeeded.
- If push fails because of permissions, auth, branch protection, or remote state, report that honestly.
