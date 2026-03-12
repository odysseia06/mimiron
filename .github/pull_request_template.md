## Summary

Brief description of the changes.

## What changed

- ...
- ...

## Type of change

- [ ] Bug fix
- [ ] New skill or agent
- [ ] New hook/guard script
- [ ] Documentation
- [ ] CI/tooling
- [ ] Other: ...

## Security checklist

If this PR touches security-sensitive areas, verify:

- [ ] No new Bash tool access added without justification
- [ ] Guard script deny patterns not weakened
- [ ] Agent permissionMode not escalated
- [ ] No force-push, default-branch push, or destructive commands added
- [ ] No new `gh` commands that modify repository state
- [ ] Prompt injection risks considered for any skill that reads external input

## Testing

- [ ] Smoke tests pass (`bash tests/smoke/test_structure.sh`)
- [ ] Guard script tests pass (`python3 tests/smoke/test_guard_script.py`)
- [ ] Verification passes (`bash install/verify.sh --source .`)
- [ ] Manual testing performed (describe below)

## CHANGELOG

- [ ] Updated `CHANGELOG.md` under `[Unreleased]`
