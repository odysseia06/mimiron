# Architecture

## Overview

Mimiron is a multi-agent skills and automation repository. It provides parallel implementation surfaces for different AI coding agents, with each agent family getting its own directory, conventions, and distribution path.

Currently supported:
- **Claude Code** — fully implemented skills, agents, and hooks under `.claude/`
- **Codex** — placeholder skill skeletons under `.agents/`

## Repository layout

```
mimiron/
├── plugin.json                          # Claude Code plugin manifest
├── AGENTS.md                            # Codex repository guide
├── .claude/                             # Claude Code runtime assets
│   ├── skills/
│   │   └── solve-issue/
│   │       ├── SKILL.md
│   │       ├── templates/
│   │       └── examples/
│   ├── agents/
│   │   └── issue-implementer.md
│   └── scripts/
│       └── guard_bash_commands.py
├── .agents/                             # Codex runtime assets (placeholders)
│   ├── skills/
│   │   └── solve-issue/
│   │       └── SKILL.md                 # Stub — not yet authored
│   └── openai.yaml                      # Implicit invocation disabled
├── install/                             # Optional manual installers
│   ├── install.sh / install.ps1         # Claude installer
│   ├── uninstall.sh / uninstall.ps1     # Claude uninstaller
│   ├── verify.sh / verify.ps1           # Claude verifier
│   ├── install-codex.sh                 # Codex installer
│   └── verify-codex.sh                  # Codex verifier
├── docs/                                # Documentation
├── tests/                               # Smoke tests and fixtures
├── manifests/                           # Install manifests (gitignored)
├── .github/                             # CI workflows and templates
└── [community files]                    # README, LICENSE, CONTRIBUTING, etc.
```

### Why this layout

**`.claude/` and `.agents/` as parallel surfaces** — each agent family has its own hidden directory at the repo root. This mirrors the target installation layout and means the repo itself can serve as a development environment where both agents see their native assets.

**`plugin.json` for Claude distribution** — Claude Code's plugin system is the primary distribution path for Claude assets. The plugin manifest references files under `.claude/`.

**`AGENTS.md` for Codex awareness** — Codex-aware agents and contributors read `AGENTS.md` to understand the repo structure.

**Separate install scripts per agent** — Claude and Codex have different target directories and conventions. Each agent gets its own install/verify scripts.

## Claude Code architecture

### Skills

Each skill lives in its own directory under `.claude/skills/`:

```
.claude/skills/<skill-name>/
├── SKILL.md              # Skill definition (YAML frontmatter + instructions)
├── templates/            # Template files referenced by the skill
└── examples/             # Example files referenced by the skill
```

### Agents

Agents are single Markdown files under `.claude/agents/` with YAML frontmatter declaring model, tools, permission mode, max turns, and hook configurations.

### Guard scripts

Guard scripts are Python scripts under `.claude/scripts/` that implement the Claude Code PreToolUse hook protocol: read JSON from stdin, evaluate against safety rules, output a deny decision or exit silently to allow.

## Codex architecture

Codex assets live under `.agents/`. Currently, these are placeholders only:

- `.agents/skills/solve-issue/SKILL.md` — minimal stub with frontmatter
- `.agents/openai.yaml` — `allow_implicit_invocation: false` to prevent accidental use

Codex does not have the same hook, permission mode, or allowed-tools concepts as Claude Code. When Codex skills are authored, they will use Codex-native conventions.

## Scope model

| Scope | Claude plugin install | Claude manual install | Codex manual install |
|---|---|---|---|
| Project | `claude plugin add` | `install.sh --scope project --target .` | `install-codex.sh --target .` |
| User | `claude plugin add --scope user` | `install.sh --scope user` | N/A |
| Local dev | `claude plugin add --scope local` | `install.sh --scope project --mode symlink` | `install-codex.sh --mode symlink` |

## Extension model

To add new capabilities:

1. **New Claude skill** — create `.claude/skills/<name>/SKILL.md`, register in `plugin.json`
2. **New Claude agent** — create `.claude/agents/<name>.md`, register in `plugin.json`
3. **New guard script** — create `.claude/scripts/<name>.py`, reference from agent hooks
4. **New Codex skill** — create `.agents/skills/<name>/SKILL.md` using Codex conventions
