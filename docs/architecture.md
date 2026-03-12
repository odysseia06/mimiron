# Architecture

## Overview

Mimiron is a Claude Code extension pack distributed as a **plugin** first, with optional manual installer scripts as a secondary path. This document explains the architectural decisions and repo layout.

## Why plugin-first

Claude Code supports a native plugin system that handles discovery, installation, version management, and asset loading. By packaging Mimiron as a plugin:

- Users install with a single command (`claude plugin add`)
- Claude Code handles path resolution and asset registration
- Updates flow through the plugin system
- No manual file copying is required for the common case
- Project-level and user-level scoping work natively

The alternative — requiring users to run shell scripts and manage `.claude/` directories manually — is more fragile and less discoverable. The installer scripts exist as a fallback, not the primary path.

## Repository layout

```
mimiron/
├── plugin.json                          # Plugin manifest (primary packaging)
├── skills/                              # Claude Code skills
│   └── solve-issue/
│       ├── SKILL.md                     # Skill definition
│       ├── templates/                   # Supporting templates
│       └── examples/                    # Response format examples
├── agents/                              # Subagent definitions
│   └── issue-implementer.md
├── scripts/                             # Hook and guard scripts
│   └── guard_bash_commands.py
├── install/                             # Optional manual installers
│   ├── install.sh
│   ├── uninstall.sh
│   ├── verify.sh
│   ├── install.ps1
│   ├── uninstall.ps1
│   └── verify.ps1
├── manifests/                           # Install manifests (generated, gitignored)
├── docs/                                # Documentation
├── tests/                               # Smoke tests and fixtures
├── .github/                             # CI workflows and templates
└── [community files]                    # README, LICENSE, CONTRIBUTING, etc.
```

### Why this layout

**Skills, agents, and scripts at the top level** — These are the runtime assets Claude Code consumes. Placing them at the repo root (rather than under `src/`) keeps the plugin structure flat and aligned with what Claude Code expects. The `plugin.json` references these paths directly.

**Install scripts under `install/`** — Separated from runtime assets to make it clear these are optional convenience tools. They are not loaded by the plugin system.

**Manifests under `manifests/`** — Generated at install time by the manual installer scripts. Gitignored because they are environment-specific.

**Tests under `tests/`** — Smoke tests validate repo structure and script correctness. They run in CI and can be run locally.

## Skill architecture

Each skill lives in its own directory under `skills/`:

```
skills/<skill-name>/
├── SKILL.md              # Skill definition (YAML frontmatter + instructions)
├── templates/            # Template files referenced by the skill
└── examples/             # Example files referenced by the skill
```

This self-contained structure means:
- Adding a skill does not require touching other skills
- Skills can reference their own templates and examples via relative paths
- The plugin manifest registers each skill by path

## Agent architecture

Agents are single Markdown files under `agents/` with YAML frontmatter that declares:
- Model, tools, permission mode, max turns
- Hook configurations (PreToolUse guards, Stop validation)

Agents are referenced by name from skills (via the `agent:` frontmatter field).

## Guard script architecture

Guard scripts are Python scripts under `scripts/` that:
- Read a JSON payload from stdin (Claude Code hook protocol)
- Evaluate the tool invocation against safety rules
- Output a JSON deny decision or exit silently to allow

The guard pattern is intentionally simple — a single script per concern, no framework, no dependencies beyond the Python standard library.

## Extension model

To add new capabilities:

1. **New skill** → create `skills/<name>/SKILL.md` + supporting files, register in `plugin.json`
2. **New agent** → create `agents/<name>.md`, register in `plugin.json`
3. **New guard** → create `scripts/<name>.py`, reference from agent hooks
4. **New template** → add under the relevant skill's `templates/` directory

Each extension type has a clear place, a registration step, and a test expectation.

## Scope model

| Scope | Plugin install | Manual install | Use case |
|---|---|---|---|
| Project | `claude plugin add --scope project` | `install.sh --scope project --target .` | Team repos, shared config |
| User | `claude plugin add --scope user` | `install.sh --scope user` | Personal global setup |
| Local | Clone + `claude plugin add --scope local` | `install.sh --scope project --mode symlink` | Development and testing |

Project scope is the recommended default for teams. User scope is for individuals who want the skills available everywhere.
