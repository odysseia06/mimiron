# Release process

## Versioning

[Semantic Versioning](https://semver.org/):
- **MAJOR** — breaking changes to interfaces, manifest format, or install behavior
- **MINOR** — new skills, agents, or features
- **PATCH** — bug fixes, docs, guard script improvements

Version stored in `VERSION` and `plugin.json`.

## Release checklist

```bash
git checkout main && git pull origin main

# Tests
bash tests/smoke/test_structure.sh
python3 tests/smoke/test_guard_script.py
bash install/verify.sh --source .
bash install/verify-codex.sh --source .
```

1. Update `VERSION` and `plugin.json` version
2. Move `[Unreleased]` items in `CHANGELOG.md` to new version section
3. Commit, tag, push:

```bash
git add VERSION plugin.json CHANGELOG.md
git commit -m "Release v0.2.0"
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin main && git push origin v0.2.0
```

4. Create GitHub release:

```bash
gh release create v0.2.0 --title "v0.2.0" --notes "See CHANGELOG.md for details."
```

## Changelog conventions

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/): Added, Changed, Deprecated, Removed, Fixed, Security.
