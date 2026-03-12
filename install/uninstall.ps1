<#
.SYNOPSIS
    Uninstalls Mimiron assets from a target project or user-level .claude/ directory.

.DESCRIPTION
    Reads the install manifest and removes only the files that Mimiron installed.
    Restores backups if they exist. Removes empty directories created by the installer.

.PARAMETER Target
    Path to the target project root. Required for project scope.
    Defaults to $env:USERPROFILE for user scope.

.PARAMETER Scope
    Installation scope: "project" or "user". Default: "project".

.PARAMETER DryRun
    Show what would happen without making changes.

.EXAMPLE
    .\uninstall.ps1 -Target C:\Projects\my-app
.EXAMPLE
    .\uninstall.ps1 -Scope user
.EXAMPLE
    .\uninstall.ps1 -Target C:\Projects\my-app -DryRun
#>

[CmdletBinding()]
param(
    [string]$Target,

    [ValidateSet("project", "user")]
    [string]$Scope = "project",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Test-DirectoryEmpty {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $true }
    $items = Get-ChildItem -Path $Path -Force
    return ($null -eq $items -or $items.Count -eq 0)
}

# --- Resolve target ----------------------------------------------------------

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

Write-Status "Mimiron uninstaller"
Write-Status "Target: $CLAUDE_DIR"
if ($DryRun) { Write-Status "DRY RUN - no changes will be made" "dry-run" }
Write-Host ""

# --- Read manifest -----------------------------------------------------------

if (-not (Test-Path $MANIFEST_FILE)) {
    Write-Status "No install manifest found at $MANIFEST_FILE. Was Mimiron installed here?" "error"
    exit 1
}

try {
    $manifest = Get-Content $MANIFEST_FILE -Raw | ConvertFrom-Json
} catch {
    Write-Status "Failed to parse manifest: $($_.Exception.Message)" "error"
    exit 1
}

$packName = if ($manifest.pack) { $manifest.pack } else { "mimiron" }
$version = if ($manifest.version) { $manifest.version } else { "unknown" }

Write-Status "Uninstalling $packName v$version"
Write-Host ""

# --- Remove installed files --------------------------------------------------

$fileEntries = @()
if ($manifest.files) {
    $fileEntries = @($manifest.files)
}

foreach ($relPath in $fileEntries) {
    if (-not $relPath) { continue }
    $fullPath = Join-Path $CLAUDE_DIR $relPath

    if (Test-Path $fullPath) {
        if ($DryRun) {
            Write-Status "Would remove: $fullPath" "info"
        } else {
            Remove-Item -Path $fullPath -Force
            Write-Status "Removed: $fullPath" "ok"
        }
    } else {
        Write-Status "Already absent: $fullPath" "warn"
    }
}

# --- Restore backups ---------------------------------------------------------

$backupEntries = @()
if ($manifest.backups) {
    $backupEntries = @($manifest.backups)
}

foreach ($entry in $backupEntries) {
    if (-not $entry) { continue }
    $backupFile = $entry.file
    $backupPath = $entry.backup

    if ($backupPath -and (Test-Path $backupPath)) {
        $targetPath = Join-Path $CLAUDE_DIR $backupFile
        if ($DryRun) {
            Write-Status "Would restore backup: $backupPath -> $targetPath" "info"
        } else {
            Move-Item -Path $backupPath -Destination $targetPath -Force
            Write-Status "Restored backup: $targetPath" "ok"
        }
    }
}

# --- Remove empty directories (deepest first) -------------------------------

# Collect directories that were explicitly created by the installer
$dirsToCheck = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

if ($manifest.directories_created) {
    foreach ($d in @($manifest.directories_created)) {
        if ($d) { [void]$dirsToCheck.Add($d) }
    }
}

# Also check standard Mimiron directories under .claude/
$standardDirs = @(
    (Join-Path $CLAUDE_DIR "skills/solve-issue/examples"),
    (Join-Path $CLAUDE_DIR "skills/solve-issue/templates"),
    (Join-Path $CLAUDE_DIR "skills/solve-issue"),
    (Join-Path $CLAUDE_DIR "skills"),
    (Join-Path $CLAUDE_DIR "agents"),
    (Join-Path $CLAUDE_DIR "scripts")
)
foreach ($d in $standardDirs) {
    [void]$dirsToCheck.Add($d)
}

# Sort deepest first (by path length descending) and remove if empty
$sortedDirs = $dirsToCheck | Sort-Object { $_.Length } -Descending

foreach ($dir in $sortedDirs) {
    if (-not (Test-Path $dir)) { continue }
    if (-not (Test-DirectoryEmpty $dir)) { continue }

    if ($DryRun) {
        Write-Status "Would remove empty directory: $dir" "info"
    } else {
        Remove-Item -Path $dir -Force
        Write-Status "Removed empty directory: $dir" "ok"
    }
}

# --- Remove manifest ---------------------------------------------------------

if ($DryRun) {
    Write-Status "Would remove manifest: $MANIFEST_FILE" "info"
    Write-Status "Would remove manifest directory: $MANIFEST_DIR" "info"
} else {
    if (Test-Path $MANIFEST_FILE) {
        Remove-Item -Path $MANIFEST_FILE -Force
    }
    if ((Test-Path $MANIFEST_DIR) -and (Test-DirectoryEmpty $MANIFEST_DIR)) {
        Remove-Item -Path $MANIFEST_DIR -Force
    }
    Write-Status "Removed manifest" "ok"
}

# --- Summary -----------------------------------------------------------------

Write-Host ""
if ($DryRun) {
    Write-Status "Dry run complete. No changes were made." "info"
    Write-Status "Run without -DryRun to uninstall." "info"
} else {
    Write-Status "Mimiron uninstalled from $CLAUDE_DIR" "ok"
}

exit 0
