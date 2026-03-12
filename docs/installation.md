# Installation

Mimiron supports separate install paths for each agent family.

## Claude Code

### Plugin install (recommended)

```bash
# Project-level (recommended for teams)
claude plugin add github:odysseia06/mimiron

# User-level
claude plugin add --scope user github:odysseia06/mimiron

# From a local path (development)
claude plugin add --scope local /path/to/mimiron
```

### Manual install

```bash
# Dry-run first
bash install/install.sh --target /path/to/project --scope project --dry-run

# Install with file copies
bash install/install.sh --target /path/to/project --scope project

# Install with symlinks (development)
bash install/install.sh --target /path/to/project --scope project --mode symlink

# User-level
bash install/install.sh --scope user
```

### Windows (PowerShell)

```powershell
.\install\install.ps1 -Target C:\path\to\project -Scope project
.\install\install.ps1 -Scope user
.\install\install.ps1 -Scope project -Target . -DryRun
```

### What gets installed (Claude)

```
.claude/
├── skills/
│   └── solve-issue/
│       ├── SKILL.md
│       ├── templates/
│       │   └── issue-followup-comment.md
│       └── examples/
│           └── final-response-format.md
├── agents/
│   └── issue-implementer.md
└── scripts/
    └── guard_bash_commands.py
```

## Codex

### Manual install

```bash
bash install/install-codex.sh --target /path/to/project --dry-run
bash install/install-codex.sh --target /path/to/project
bash install/install-codex.sh --target /path/to/project --mode symlink
```

Note: Codex skills are placeholders only and are not yet functional.

### What gets installed (Codex)

```
.agents/
├── skills/
│   └── solve-issue/
│       └── SKILL.md          # Placeholder stub
└── openai.yaml                # allow_implicit_invocation: false
```

## Verification

```bash
# Verify Claude plugin structure (from repo root)
bash install/verify.sh --source .

# Verify a Claude manual install
bash install/verify.sh --target /path/to/project

# Verify Codex structure
bash install/verify-codex.sh --source .
```

Exit code 0 means everything checks out.

## Uninstall

### Claude — plugin

```bash
claude plugin remove mimiron
```

### Claude — manual

```bash
bash install/uninstall.sh --target /path/to/project --dry-run
bash install/uninstall.sh --target /path/to/project
```

### Windows

```powershell
.\install\uninstall.ps1 -Target C:\path\to\project
```

The uninstall script reads the install manifest, removes only files Mimiron installed, restores backups, and cleans up empty directories.

## Troubleshooting

### "Permission denied" on guard script

```bash
chmod +x .claude/scripts/guard_bash_commands.py
```

### Symlinks broken after moving the source repo

Reinstall or switch to copy mode.

### Skills not showing up after manual install

Ensure files are under the correct `.claude/` directory for your scope:
- Project-level: `<project-root>/.claude/`
- User-level: `~/.claude/`
