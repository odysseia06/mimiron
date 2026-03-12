# Changelog

All notable changes to Mimiron will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Restructured as a multi-agent repository — no longer Claude-only
- Moved Claude runtime assets into `.claude/` (skills, agents, scripts)
- Updated `plugin.json` paths to reference `.claude/` source layout
- Rewrote all documentation for multi-agent positioning
- Separated security model into Claude-specific and Codex-specific sections
- Updated install/uninstall/verify scripts for new `.claude/` source paths

### Added
- Codex placeholder skill skeletons under `.agents/skills/`
- `.agents/openai.yaml` with `allow_implicit_invocation: false`
- `AGENTS.md` repository guide for Codex-aware contributors
- `install/install-codex.sh` — Codex manual installer
- `install/verify-codex.sh` — Codex structure verifier
- Smoke test coverage for Codex placeholders and `.agents/` structure

## [0.1.0] - Unreleased

### Added
- Initial repository scaffold
- `solve-issue` skill for end-to-end GitHub issue implementation
- `issue-implementer` subagent with guardrails and completion validation
- `guard_bash_commands.py` PreToolUse hook script
- Plugin manifest (`plugin.json`) for Claude Code plugin distribution
- Optional install/uninstall/verify scripts for manual setup
- Documentation: architecture, installation, usage, security model, authoring guide, release process
- CI workflows for structure validation and smoke tests
- Issue templates and PR template
