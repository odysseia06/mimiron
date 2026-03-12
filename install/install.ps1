<#
.SYNOPSIS
    Installs Mimiron assets into a target project or user-level .claude/ directory.

.DESCRIPTION
    Copies or symlinks Mimiron skills, agents, and scripts into the target's .claude/
    directory. Creates a JSON manifest for later uninstall and verification.

    The primary install path is: claude plugin add github:odysseia06/mimiron
    This script is an optional convenience for manual setup.

.PARAMETER Target
    Path to the target project root. Required for project scope.
    Defaults to $env:USERPROFILE for user scope.

.PARAMETER Scope
    Installation scope: "project" or "user". Default: "project".

.PARAMETER Mode
    Installation mode: "copy" or "symlink". Default: "copy".

.PARAMETER DryRun
    Show what would happen without making changes.

.PARAMETER Force
    Allow overwriting existing files. Backups are still created.

.EXAMPLE
    .\install.ps1 -Target C:\Projects\my-app -Scope project
.EXAMPLE
    .\install.ps1 -Scope user
.EXAMPLE
    .\install.ps1 -Target C:\Projects\my-app -Mode symlink -DryRun
#>

[CmdletBinding()]
param(
    [string]$Target,

    [ValidateSet("project", "user")]
    [string]$Scope = "project",

    [ValidateSet("copy", "symlink")]
    [string]$Mode = "copy",

    [switch]$DryRun,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Constants ---------------------------------------------------------------

$PACK_NAME = "mimiron"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SOURCE_ROOT = (Resolve-Path (Join-Path $SCRIPT_DIR "..")).Path

# Files to install: source (relative to SOURCE_ROOT) -> target (relative to .claude/)
# Format matches the bash script: "source_rel|target_rel"
$INSTALL_MAP = @(
    @{ Source = ".claude/skills/solve-issue/SKILL.md";                            Target = "skills/solve-issue/SKILL.md" }
    @{ Source = ".claude/skills/solve-issue/templates/issue-followup-comment.md"; Target = "skills/solve-issue/templates/issue-followup-comment.md" }
    @{ Source = ".claude/skills/solve-issue/examples/final-response-format.md";   Target = "skills/solve-issue/examples/final-response-format.md" }
    @{ Source = ".claude/agents/issue-implementer.md";                            Target = "agents/issue-implementer.md" }
    @{ Source = ".claude/scripts/guard_bash_commands.py";                         Target = "scripts/guard_bash_commands.py" }
)

# --- Helpers -----------------------------------------------------------------

function Write-Status {
    param([string]$Message, [string]$Level = "info")
    switch ($Level) {
        "info"    { Write-Host "[info]    $Message" -ForegroundColor Blue }
        "ok"      { Write-Host "[ok]      $Message" -ForegroundColor Green }
        "warn"    { Write-Host "[warn]    $Message" -ForegroundColor Yellow }
        "error"   { Write-Host "[error]   $Message" -ForegroundColor Red }
        "dry-run" { Write-Host "[dry-run] $Message" -ForegroundColor Magenta }
    }
}

function Get-FileHash256 {
    param([string]$FilePath)
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
}

# --- Resolve target directory ------------------------------------------------

# Read version
$VERSION = ""
$versionPath = Join-Path $SOURCE_ROOT "VERSION"
if (Test-Path $versionPath) {
    $VERSION = (Get-Content $versionPath -Raw).Trim()
}

if ($Scope -eq "user") {
    if (-not $Target) {
        $Target = $env:USERPROFILE
    }
} else {
    if (-not $Target) {
        Write-Status "-Target is required for project scope." "error"
        exit 1
    }
}

if (-not (Test-Path $Target)) {
    Write-Status "Target directory does not exist: $Target" "error"
    exit 1
}

$Target = (Resolve-Path $Target).Path
$CLAUDE_DIR = Join-Path $Target ".claude"
$MANIFEST_DIR = Join-Path $CLAUDE_DIR ".mimiron"
$MANIFEST_FILE = Join-Path $MANIFEST_DIR "manifest.json"

Write-Status "Mimiron installer v${VERSION}"
Write-Status "Source:  $SOURCE_ROOT"
Write-Status "Target:  $CLAUDE_DIR"
Write-Status "Scope:   $Scope"
Write-Status "Mode:    $Mode"
if ($DryRun) { Write-Status "DRY RUN - no changes will be made" "dry-run" }
Write-Host ""

# --- Verify source -----------------------------------------------------------

foreach ($entry in $INSTALL_MAP) {
    $srcPath = Join-Path $SOURCE_ROOT $entry.Source
    if (-not (Test-Path $srcPath)) {
        Write-Status "Source file missing: $srcPath" "error"
        exit 1
    }
}

# --- Check for conflicts without -Force --------------------------------------

if (-not $Force) {
    foreach ($entry in $INSTALL_MAP) {
        $tgtPath = Join-Path $CLAUDE_DIR $entry.Target
        if (Test-Path $tgtPath) {
            Write-Status "Target exists: $tgtPath -- use -Force to overwrite (backup will be created)" "error"
            exit 1
        }
    }
}

# --- Install files -----------------------------------------------------------

$TIMESTAMP = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")

[System.Collections.ArrayList]$installedFiles = @()
[System.Collections.ArrayList]$createdDirs = @()
[System.Collections.ArrayList]$backups = @()

foreach ($entry in $INSTALL_MAP) {
    $srcRel = $entry.Source
    $tgtRel = $entry.Target
    $srcPath = Join-Path $SOURCE_ROOT $srcRel
    $tgtPath = Join-Path $CLAUDE_DIR $tgtRel
    $tgtDir = Split-Path -Parent $tgtPath

    # Create target directory
    if (-not (Test-Path $tgtDir)) {
        if ($DryRun) {
            Write-Status "Would create directory: $tgtDir" "info"
        } else {
            New-Item -ItemType Directory -Path $tgtDir -Force | Out-Null
            [void]$createdDirs.Add($tgtDir)
            Write-Status "Created directory: $tgtDir" "info"
        }
    }

    # Handle existing file
    if (Test-Path $tgtPath) {
        # -Force was already validated above; if we get here, Force is set
        $backupPath = "${tgtPath}.mimiron-backup.${TIMESTAMP}"
        if ($DryRun) {
            Write-Status "Would backup: $tgtPath -> $backupPath" "info"
        } else {
            Copy-Item -Path $tgtPath -Destination $backupPath -Force
            [void]$backups.Add(@{ file = $tgtRel; backup = $backupPath })
            Write-Status "Backed up: $tgtPath -> $backupPath" "info"
        }
    }

    # Install
    if ($Mode -eq "symlink") {
        if ($DryRun) {
            Write-Status "Would symlink: $tgtPath -> $srcPath" "info"
        } else {
            # Remove existing file/symlink before creating new symlink
            if (Test-Path $tgtPath) {
                Remove-Item -Path $tgtPath -Force
            }
            New-Item -ItemType SymbolicLink -Path $tgtPath -Target $srcPath | Out-Null
            Write-Status "Symlinked: $tgtPath -> $srcPath" "ok"
        }
    } else {
        if ($DryRun) {
            Write-Status "Would copy: $srcPath -> $tgtPath" "info"
        } else {
            Copy-Item -Path $srcPath -Destination $tgtPath -Force
            Write-Status "Copied: $srcPath -> $tgtPath" "ok"
        }
    }

    [void]$installedFiles.Add($tgtRel)
}

# --- Write manifest ----------------------------------------------------------

if (-not $DryRun) {
    if (-not (Test-Path $MANIFEST_DIR)) {
        New-Item -ItemType Directory -Path $MANIFEST_DIR -Force | Out-Null
    }

    # Build manifest matching the bash script format
    $manifest = [ordered]@{
        pack                = $PACK_NAME
        version             = $VERSION
        installed_at        = $TIMESTAMP
        source_root         = $SOURCE_ROOT
        target_root         = $Target
        claude_dir          = $CLAUDE_DIR
        install_mode        = $Mode
        install_scope       = $Scope
        files               = [string[]]$installedFiles
        directories_created = [string[]]$createdDirs
        backups             = $backups.ToArray()
        verified            = $false
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $MANIFEST_FILE -Encoding UTF8
    Write-Status "Manifest written: $MANIFEST_FILE" "ok"
} else {
    Write-Status "Would write manifest: $MANIFEST_FILE" "info"
}

# --- Summary -----------------------------------------------------------------

Write-Host ""
if ($DryRun) {
    Write-Status "Dry run complete. No changes were made." "info"
    Write-Status "Run without -DryRun to install." "info"
} else {
    Write-Status "Mimiron v${VERSION} installed to $CLAUDE_DIR" "ok"
    Write-Status "Verify with: .\install\verify.ps1 -Target $Target" "info"
    Write-Status "Uninstall with: .\install\uninstall.ps1 -Target $Target" "info"
}

exit 0
