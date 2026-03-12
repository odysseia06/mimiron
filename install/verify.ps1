<#
.SYNOPSIS
    Verifies the Mimiron plugin source structure and/or a target installation.

.DESCRIPTION
    When given -Source, validates the Mimiron repo structure (plugin.json, required
    files, SKILL.md frontmatter). When given -Target, validates an installation
    against the manifest and source files. At least one of -Source or -Target is
    required. Both may be provided.

.PARAMETER Source
    Path to the Mimiron repository root. Verifies plugin structure.

.PARAMETER Target
    Path to a target where Mimiron was installed. Verifies installation integrity.

.EXAMPLE
    .\verify.ps1 -Source C:\repos\mimiron
.EXAMPLE
    .\verify.ps1 -Target C:\Projects\my-app
.EXAMPLE
    .\verify.ps1 -Source C:\repos\mimiron -Target C:\Projects\my-app
#>

[CmdletBinding()]
param(
    [string]$Source,
    [string]$Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers -----------------------------------------------------------------

# Counters at script scope so nested functions can modify them
$script:ERRORS = 0
$script:WARNINGS = 0

function Write-Pass {
    param([string]$Message)
    Write-Host "[pass]  $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL]  $Message" -ForegroundColor Red
    $script:ERRORS++
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[warn]  $Message" -ForegroundColor Yellow
    $script:WARNINGS++
}

function Write-Info {
    param([string]$Message)
    Write-Host "[info]  $Message" -ForegroundColor Blue
}

function Get-FileHash256 {
    param([string]$FilePath)
    (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-YamlFrontmatter {
    param([string]$FilePath)
    $lines = Get-Content -Path $FilePath -TotalCount 1
    if (-not $lines -or $lines.Count -lt 1) { return $false }
    return ($lines[0].Trim() -eq "---")
}

function Test-IsSymlink {
    param([string]$FilePath)
    $item = Get-Item -Path $FilePath -Force
    return [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
}

function Get-SymlinkTarget {
    param([string]$FilePath)
    $item = Get-Item -Path $FilePath -Force
    return $item.Target
}

# --- Validate arguments ------------------------------------------------------

if (-not $Source -and -not $Target) {
    Write-Fail "At least one of -Source or -Target must be provided."
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\verify.ps1 -Source <mimiron-repo-path>"
    Write-Host "  .\verify.ps1 -Target <installed-target-path>"
    Write-Host "  .\verify.ps1 -Source <mimiron-repo-path> -Target <installed-target-path>"
    exit 1
}

# =============================================================================
# Source verification
# =============================================================================

if ($Source) {
    if (-not (Test-Path $Source)) {
        Write-Fail "Source directory does not exist: $Source"
        exit 1
    }
    $Source = (Resolve-Path $Source).Path

    Write-Host ""
    Write-Info "Verifying plugin structure: $Source"
    Write-Host ""

    # --- plugin.json ---------------------------------------------------------

    $pluginJsonPath = Join-Path $Source "plugin.json"
    if (-not (Test-Path $pluginJsonPath)) {
        Write-Fail "plugin.json missing"
    } else {
        Write-Pass "plugin.json exists"

        # Validate JSON
        $pluginJson = $null
        try {
            $pluginJson = Get-Content $pluginJsonPath -Raw | ConvertFrom-Json
            Write-Pass "plugin.json is valid JSON"
        } catch {
            Write-Fail "plugin.json is not valid JSON: $($_.Exception.Message)"
        }
    }

    # --- VERSION file --------------------------------------------------------

    $versionPath = Join-Path $Source "VERSION"
    if (Test-Path $versionPath) {
        Write-Pass "VERSION file exists"
    } else {
        Write-Fail "VERSION file missing"
    }

    # --- Expected runtime files ----------------------------------------------

    $expectedFiles = @(
        ".claude/skills/solve-issue/SKILL.md",
        ".claude/skills/solve-issue/templates/issue-followup-comment.md",
        ".claude/skills/solve-issue/examples/final-response-format.md",
        ".claude/agents/issue-implementer.md",
        ".claude/scripts/guard_bash_commands.py"
    )

    foreach ($f in $expectedFiles) {
        $fullPath = Join-Path $Source $f
        if (Test-Path $fullPath) {
            Write-Pass "Found: $f"
        } else {
            Write-Fail "Missing: $f"
        }
    }

    # --- SKILL.md has frontmatter --------------------------------------------

    $skillFile = Join-Path $Source ".claude/skills/solve-issue/SKILL.md"
    if (Test-Path $skillFile) {
        if (Test-YamlFrontmatter $skillFile) {
            Write-Pass "SKILL.md has YAML frontmatter"
        } else {
            Write-Fail "SKILL.md missing YAML frontmatter"
        }
    }

    # --- Agent has frontmatter -----------------------------------------------

    $agentFile = Join-Path $Source ".claude/agents/issue-implementer.md"
    if (Test-Path $agentFile) {
        if (Test-YamlFrontmatter $agentFile) {
            Write-Pass "issue-implementer.md has YAML frontmatter"
        } else {
            Write-Fail "issue-implementer.md missing YAML frontmatter"
        }
    }

    # --- Guard script checks -------------------------------------------------

    $guardFile = Join-Path $Source ".claude/scripts/guard_bash_commands.py"
    if (Test-Path $guardFile) {
        # Has shebang
        $firstLine = (Get-Content -Path $guardFile -TotalCount 1)
        if ($firstLine -and $firstLine -match '^#!/usr/bin/env python3') {
            Write-Pass "guard_bash_commands.py has correct shebang"
        } else {
            Write-Warn "guard_bash_commands.py has unexpected shebang"
        }
    }

    # --- plugin.json references resolve to existing files --------------------

    if ($pluginJson) {
        $allRefsOk = $true
        foreach ($section in @("skills", "agents", "scripts")) {
            $entries = $pluginJson.$section
            if (-not $entries) { continue }
            foreach ($entry in $entries) {
                $refPath = $entry.path
                if (-not $refPath) { continue }
                $fullRefPath = Join-Path $Source $refPath
                if (-not (Test-Path $fullRefPath)) {
                    Write-Fail "plugin.json references missing file: $refPath"
                    $allRefsOk = $false
                }
            }
        }
        if ($allRefsOk) {
            Write-Pass "All plugin.json references resolve to existing files"
        }
    }

    # --- Codex files ---------------------------------------------------------

    $codexSkillFile = Join-Path $Source ".agents/skills/solve-issue/SKILL.md"
    if (Test-Path $codexSkillFile) {
        Write-Pass "Found: .agents/skills/solve-issue/SKILL.md"
        if (Test-YamlFrontmatter $codexSkillFile) {
            Write-Pass ".agents/skills/solve-issue/SKILL.md has YAML frontmatter"
        } else {
            Write-Fail ".agents/skills/solve-issue/SKILL.md missing YAML frontmatter"
        }
    } else {
        Write-Fail "Missing: .agents/skills/solve-issue/SKILL.md"
    }

    $codexYamlFile = Join-Path $Source ".agents/openai.yaml"
    if (Test-Path $codexYamlFile) {
        Write-Pass "Found: .agents/openai.yaml"
        $codexYamlContent = Get-Content $codexYamlFile -Raw
        if ($codexYamlContent -match "allow_implicit_invocation: false") {
            Write-Pass ".agents/openai.yaml contains 'allow_implicit_invocation: false'"
        } else {
            Write-Fail ".agents/openai.yaml missing 'allow_implicit_invocation: false'"
        }
    } else {
        Write-Fail "Missing: .agents/openai.yaml"
    }

    $agentsMdFile = Join-Path $Source "AGENTS.md"
    if (Test-Path $agentsMdFile) {
        Write-Pass "Found: AGENTS.md"
    } else {
        Write-Fail "Missing: AGENTS.md"
    }

    # --- Essential docs ------------------------------------------------------

    foreach ($doc in @("README.md", "LICENSE", "CONTRIBUTING.md", "SECURITY.md")) {
        $docPath = Join-Path $Source $doc
        if (Test-Path $docPath) {
            Write-Pass "Found: $doc"
        } else {
            Write-Warn "Missing: $doc"
        }
    }
}

# =============================================================================
# Target verification
# =============================================================================

if ($Target) {
    if (-not (Test-Path $Target)) {
        Write-Fail "Target directory does not exist: $Target"
        exit 1
    }
    $Target = (Resolve-Path $Target).Path
    $claudeDir = Join-Path $Target ".claude"

    Write-Host ""
    Write-Info "Verifying installation: $claudeDir"
    Write-Host ""

    if (-not (Test-Path $claudeDir)) {
        Write-Fail "No .claude directory found at $claudeDir"
    } else {
        # --- Expected installed files ----------------------------------------

        $expectedFiles = @(
            "skills/solve-issue/SKILL.md",
            "skills/solve-issue/templates/issue-followup-comment.md",
            "skills/solve-issue/examples/final-response-format.md",
            "agents/issue-implementer.md",
            "scripts/guard_bash_commands.py"
        )

        foreach ($f in $expectedFiles) {
            $fullPath = Join-Path $claudeDir $f
            if (Test-Path $fullPath) {
                Write-Pass "Found: .claude/$f"

                # Check symlink validity
                if (Test-IsSymlink $fullPath) {
                    $linkTarget = Get-SymlinkTarget $fullPath
                    if (Test-Path $fullPath) {
                        Write-Pass "Symlink valid: .claude/$f -> $linkTarget"
                    } else {
                        Write-Fail "Broken symlink: .claude/$f -> $linkTarget"
                    }
                }
            } else {
                Write-Fail "Missing: .claude/$f"
            }
        }

        # --- Manifest --------------------------------------------------------

        $manifestPath = Join-Path $claudeDir ".mimiron/manifest.json"
        $manifest = $null

        if (-not (Test-Path $manifestPath)) {
            Write-Warn "No install manifest found (expected if installed via plugin system)"
        } else {
            Write-Pass "Install manifest found"

            try {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                Write-Pass "Install manifest is valid JSON"
            } catch {
                Write-Fail "Install manifest is not valid JSON: $($_.Exception.Message)"
            }
        }

        # --- Verify checksums for copy mode ----------------------------------

        if ($manifest) {
            $installMode = $manifest.install_mode
            $sourceRoot = $manifest.source_root

            if ($installMode -eq "copy" -and $sourceRoot -and (Test-Path $sourceRoot)) {
                Write-Info "Verifying file checksums against source..."
                foreach ($f in $expectedFiles) {
                    $srcPath = Join-Path $sourceRoot (Join-Path ".claude" $f)
                    $tgtPath = Join-Path $claudeDir $f
                    if ((Test-Path $srcPath) -and (Test-Path $tgtPath)) {
                        $srcHash = Get-FileHash256 $srcPath
                        $tgtHash = Get-FileHash256 $tgtPath
                        if ($srcHash -eq $tgtHash) {
                            Write-Pass "Checksum match: $f"
                        } else {
                            Write-Warn "Checksum mismatch: $f (source may have been updated)"
                        }
                    }
                }
            } elseif ($installMode -eq "symlink") {
                Write-Info "Verifying symlinks point to correct sources..."
                foreach ($f in $expectedFiles) {
                    $tgtPath = Join-Path $claudeDir $f
                    if (Test-Path $tgtPath) {
                        if (Test-IsSymlink $tgtPath) {
                            $linkTarget = Get-SymlinkTarget $tgtPath
                            if ($sourceRoot) {
                                $expectedSrc = Join-Path $sourceRoot (Join-Path ".claude" $f)
                                # Normalize for comparison
                                $normalizedLink = $linkTarget.TrimEnd('\', '/')
                                $normalizedExpected = $expectedSrc.TrimEnd('\', '/')
                                if ($normalizedLink -eq $normalizedExpected) {
                                    Write-Pass "Symlink correct: .claude/$f -> $linkTarget"
                                } else {
                                    Write-Fail "Symlink mismatch: .claude/$f points to '$linkTarget', expected '$expectedSrc'"
                                }
                            }
                        } else {
                            Write-Fail "Expected symlink but found regular file: .claude/$f"
                        }
                    }
                }
            }
        }
    }
}

# =============================================================================
# Summary
# =============================================================================

Write-Host ""
Write-Host "---"

if ($script:ERRORS -gt 0) {
    Write-Fail "Verification failed: $($script:ERRORS) error(s), $($script:WARNINGS) warning(s)"
    exit 1
} else {
    if ($script:WARNINGS -gt 0) {
        Write-Pass "Verification passed with $($script:WARNINGS) warning(s)"
    } else {
        Write-Pass "Verification passed"
    }
    exit 0
}
