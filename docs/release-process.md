# Release process

## Versioning

Mimiron follows [Semantic Versioning](https://semver.org/):

- **MAJOR** — breaking changes to skill/agent interfaces, manifest format, or install behavior
- **MINOR** — new skills, agents, or features; backward-compatible additions
- **PATCH** — bug fixes, documentation updates, guard script improvements

The current version is stored in `VERSION` at the repo root and echoed in `plugin.json`.

## Release checklist

### 1. Prepare the release

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Run all smoke tests
bash tests/smoke/test_structure.sh
python3 tests/smoke/test_guard_script.py

# Verify plugin structure
bash install/verify.sh --source .
```

### 2. Update version

Update these files:
- `VERSION` — the new version number
- `plugin.json` — the `version` field

### 3. Update CHANGELOG.md

Move items from `[Unreleased]` to a new version section:

```markdown
## [0.2.0] - 2026-03-15

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

### 4. Commit and tag

```bash
git add VERSION plugin.json CHANGELOG.md
git commit -m "Release v0.2.0"
git tag -a v0.2.0 -m "Release v0.2.0"
```

### 5. Push

```bash
git push origin main
git push origin v0.2.0
```

### 6. Create GitHub release

```bash
gh release create v0.2.0 --title "v0.2.0" --notes "See CHANGELOG.md for details."
```

## Changelog conventions

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/):

- **Added** — new features
- **Changed** — changes to existing features
- **Deprecated** — features that will be removed
- **Removed** — features that were removed
- **Fixed** — bug fixes
- **Security** — security-related changes

Every PR should update `[Unreleased]` in CHANGELOG.md.

## Branch strategy

- `main` — stable, released code
- Feature branches — `feature/<description>` or `issue/<number>-<description>`
- Release branches — not used; releases are cut directly from `main`

## CI validation

The CI workflow runs on every push and PR:
- Structure validation (all expected files present)
- Guard script tests
- Plugin manifest validation
- Shell script linting (if shellcheck is available)
