# Installation

## Plugin install (recommended)

The primary way to install Mimiron is as a Claude Code plugin.

### Project-level (recommended for teams)

```bash
claude plugin add github:mimiron-dev/mimiron
```

This makes Mimiron's skills and agents available in the current project. Team members who clone the repo will get the same plugin configuration.

### User-level

```bash
claude plugin add --scope user github:mimiron-dev/mimiron
```

This makes Mimiron available across all your Claude Code sessions.

### From a local path (development)

```bash
claude plugin add --scope local /path/to/mimiron
```

Useful when developing or testing changes to Mimiron itself.

## Manual install (alternative)

For environments where the plugin system is unavailable or you prefer explicit control, use the installer scripts.

### Prerequisites

- bash 3.2+ (Linux/macOS) or PowerShell 5.1+ (Windows)
- Python 3.8+ (for guard scripts)
- git (for symlink source verification)

### Project-level install

```bash
# Dry-run first to see what will happen
bash install/install.sh --target /path/to/project --scope project --dry-run

# Install with file copies
bash install/install.sh --target /path/to/project --scope project

# Install with symlinks (good for development)
bash install/install.sh --target /path/to/project --scope project --mode symlink
```

This places assets under `/path/to/project/.claude/`.

### User-level install

```bash
# Installs to ~/.claude/
bash install/install.sh --scope user

# Dry-run
bash install/install.sh --scope user --dry-run
```

### Windows (PowerShell)

```powershell
# Project-level
.\install\install.ps1 -Target C:\path\to\project -Scope project

# User-level
.\install\install.ps1 -Scope user

# Dry-run
.\install\install.ps1 -Scope project -Target . -DryRun
```

### Install modes

| Mode | Behavior | Use case |
|---|---|---|
| `copy` (default) | Copies files to the target | Production installs, shared repos |
| `symlink` | Creates symlinks to the source repo | Local development, rapid iteration |

### What gets installed

The installer places these files relative to the target `.claude/` directory:

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

## Verification

After installing, verify that everything is in place:

```bash
# Verify plugin structure (from the Mimiron repo)
bash install/verify.sh --source .

# Verify a manual install target
bash install/verify.sh --target /path/to/project
```

The verify script checks:
- All expected files exist
- Symlinks point to correct sources (symlink mode)
- File checksums match source (copy mode)
- Scripts are executable
- Directory structure is correct

Exit code 0 means everything checks out. Non-zero means something is wrong.

## Uninstall

### Plugin uninstall

```bash
claude plugin remove mimiron
```

### Manual uninstall

```bash
# Dry-run first
bash install/uninstall.sh --target /path/to/project --dry-run

# Uninstall
bash install/uninstall.sh --target /path/to/project
```

The uninstall script:
- Reads the install manifest to know exactly what to remove
- Removes only files that Mimiron installed
- Restores any backups it created during install
- Never deletes unrelated files
- Supports dry-run

### Windows

```powershell
.\install\uninstall.ps1 -Target C:\path\to\project
.\install\uninstall.ps1 -Target C:\path\to\project -DryRun
```

## Troubleshooting

### "Permission denied" on guard script

The guard script must be executable:

```bash
chmod +x .claude/scripts/guard_bash_commands.py
```

The installer handles this automatically.

### Symlinks broken after moving the source repo

If you used `--mode symlink` and then moved the Mimiron source repo, the symlinks will break. Either:
- Reinstall with the new source path
- Switch to copy mode: `install.sh --target ... --scope project --mode copy`

### Skills not showing up after manual install

Ensure the files are under the correct `.claude/` directory for your scope:
- Project-level: `<project-root>/.claude/`
- User-level: `~/.claude/`
