#!/usr/bin/env bash
# Mimiron verification script — validates plugin structure or installation.
#
# Usage:
#   verify.sh --source <mimiron-repo-root>    # Validate plugin structure
#   verify.sh --target <project-or-user-root> # Validate installation
#   verify.sh --source . --target /path       # Both

set -euo pipefail

# --- Helpers --------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { printf "${GREEN}[pass]${NC}  %s\n" "$*"; }
fail() { printf "${RED}[FAIL]${NC}  %s\n" "$*"; ERRORS=$((ERRORS + 1)); }
warn() { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; WARNINGS=$((WARNINGS + 1)); }
info() { printf "${BLUE}[info]${NC}  %s\n" "$*"; }

usage() {
  cat <<'USAGE'
Usage:
  verify.sh --source <mimiron-repo-root>
  verify.sh --target <installed-target-root>
  verify.sh --source <path> --target <path>

Options:
  --source <path>   Path to the Mimiron repo root (validates plugin structure)
  --target <path>   Path to a project/user root (validates installation)
  -h, --help        Show this help

Exit codes:
  0  All checks passed
  1  One or more checks failed
USAGE
  exit 0
}

# --- Parse arguments ------------------------------------------------------

SOURCE=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

[[ -z "$SOURCE" && -z "$TARGET" ]] && { echo "At least one of --source or --target is required." >&2; usage; }

# --- Source verification --------------------------------------------------

verify_source() {
  local root="$1"
  root="$(cd "$root" && pwd)"

  info "Verifying plugin structure: ${root}"
  echo ""

  # plugin.json
  if [[ -f "${root}/plugin.json" ]]; then
    pass "plugin.json exists"
    # Validate JSON
    if python3 -c "import json; json.load(open('${root}/plugin.json'))" 2>/dev/null; then
      pass "plugin.json is valid JSON"
    else
      fail "plugin.json is not valid JSON"
    fi
  else
    fail "plugin.json missing"
  fi

  # VERSION
  if [[ -f "${root}/VERSION" ]]; then
    pass "VERSION file exists"
  else
    fail "VERSION file missing"
  fi

  # Expected runtime files
  local -a expected_files=(
    "skills/solve-issue/SKILL.md"
    "skills/solve-issue/templates/issue-followup-comment.md"
    "skills/solve-issue/examples/final-response-format.md"
    "agents/issue-implementer.md"
    "scripts/guard_bash_commands.py"
  )

  for f in "${expected_files[@]}"; do
    if [[ -f "${root}/${f}" ]]; then
      pass "Found: ${f}"
    else
      fail "Missing: ${f}"
    fi
  done

  # SKILL.md has frontmatter
  local skill_file="${root}/skills/solve-issue/SKILL.md"
  if [[ -f "$skill_file" ]]; then
    if head -1 "$skill_file" | grep -q '^---$'; then
      pass "SKILL.md has YAML frontmatter"
    else
      fail "SKILL.md missing YAML frontmatter"
    fi
  fi

  # Agent has frontmatter
  local agent_file="${root}/agents/issue-implementer.md"
  if [[ -f "$agent_file" ]]; then
    if head -1 "$agent_file" | grep -q '^---$'; then
      pass "issue-implementer.md has YAML frontmatter"
    else
      fail "issue-implementer.md missing YAML frontmatter"
    fi
  fi

  # Guard script is executable
  local guard="${root}/scripts/guard_bash_commands.py"
  if [[ -f "$guard" ]]; then
    if [[ -x "$guard" ]]; then
      pass "guard_bash_commands.py is executable"
    else
      fail "guard_bash_commands.py is not executable"
    fi
    # Has shebang
    if head -1 "$guard" | grep -q '^#!/usr/bin/env python3'; then
      pass "guard_bash_commands.py has correct shebang"
    else
      warn "guard_bash_commands.py has unexpected shebang"
    fi
  fi

  # Plugin.json references valid paths
  if [[ -f "${root}/plugin.json" ]]; then
    python3 -c "
import json, sys, os
root = '${root}'
with open(os.path.join(root, 'plugin.json')) as f:
    data = json.load(f)
ok = True
for section in ['skills', 'agents', 'scripts']:
    for entry in data.get(section, []):
        path = entry.get('path', '')
        if not os.path.isfile(os.path.join(root, path)):
            print(f'MISSING_REF:{path}')
            ok = False
if ok:
    print('ALL_REFS_OK')
" 2>/dev/null | while IFS= read -r line; do
      if [[ "$line" == "ALL_REFS_OK" ]]; then
        pass "All plugin.json references resolve to existing files"
      elif [[ "$line" == MISSING_REF:* ]]; then
        fail "plugin.json references missing file: ${line#MISSING_REF:}"
      fi
    done
  fi

  # Essential docs
  for doc in README.md LICENSE CONTRIBUTING.md SECURITY.md; do
    if [[ -f "${root}/${doc}" ]]; then
      pass "Found: ${doc}"
    else
      warn "Missing: ${doc}"
    fi
  done
}

# --- Target verification -------------------------------------------------

verify_target() {
  local root="$1"
  root="$(cd "$root" && pwd)"
  local claude_dir="${root}/.claude"

  info "Verifying installation: ${claude_dir}"
  echo ""

  if [[ ! -d "$claude_dir" ]]; then
    fail "No .claude directory found at ${claude_dir}"
    return
  fi

  # Expected installed files
  local -a expected_files=(
    "skills/solve-issue/SKILL.md"
    "skills/solve-issue/templates/issue-followup-comment.md"
    "skills/solve-issue/examples/final-response-format.md"
    "agents/issue-implementer.md"
    "scripts/guard_bash_commands.py"
  )

  for f in "${expected_files[@]}"; do
    local full="${claude_dir}/${f}"
    if [[ -e "$full" || -L "$full" ]]; then
      pass "Found: .claude/${f}"
      # Check symlink validity
      if [[ -L "$full" ]]; then
        if [[ -e "$full" ]]; then
          pass "Symlink valid: .claude/${f} -> $(readlink "$full")"
        else
          fail "Broken symlink: .claude/${f} -> $(readlink "$full")"
        fi
      fi
    else
      fail "Missing: .claude/${f}"
    fi
  done

  # Guard script executable
  local guard="${claude_dir}/scripts/guard_bash_commands.py"
  if [[ -f "$guard" || -L "$guard" ]]; then
    if [[ -x "$guard" ]]; then
      pass "guard_bash_commands.py is executable"
    else
      fail "guard_bash_commands.py is not executable"
    fi
  fi

  # Manifest
  local manifest="${claude_dir}/.mimiron/manifest.json"
  if [[ -f "$manifest" ]]; then
    pass "Install manifest found"
    if python3 -c "import json; json.load(open('${manifest}'))" 2>/dev/null; then
      pass "Install manifest is valid JSON"
    else
      fail "Install manifest is not valid JSON"
    fi
  else
    warn "No install manifest found (expected if installed via plugin system)"
  fi

  # If manifest exists and has source_root, verify checksums for copy mode
  if [[ -f "$manifest" ]]; then
    local mode
    mode="$(python3 -c "import json; print(json.load(open('${manifest}')).get('install_mode',''))" 2>/dev/null)"
    local source_root
    source_root="$(python3 -c "import json; print(json.load(open('${manifest}')).get('source_root',''))" 2>/dev/null)"

    if [[ "$mode" == "copy" && -n "$source_root" && -d "$source_root" ]]; then
      info "Verifying file checksums against source..."
      for f in "${expected_files[@]}"; do
        local src="${source_root}/${f}"
        local tgt="${claude_dir}/${f}"
        if [[ -f "$src" && -f "$tgt" ]]; then
          local src_sum tgt_sum
          src_sum="$(sha256sum "$src" 2>/dev/null | cut -d' ' -f1)" || src_sum=""
          tgt_sum="$(sha256sum "$tgt" 2>/dev/null | cut -d' ' -f1)" || tgt_sum=""
          if [[ -n "$src_sum" && "$src_sum" == "$tgt_sum" ]]; then
            pass "Checksum match: ${f}"
          else
            warn "Checksum mismatch: ${f} (source may have been updated)"
          fi
        fi
      done
    fi
  fi
}

# --- Run ------------------------------------------------------------------

[[ -n "$SOURCE" ]] && verify_source "$SOURCE"
[[ -n "$TARGET" ]] && verify_target "$TARGET"

# --- Summary --------------------------------------------------------------

echo ""
echo "---"
if [[ $ERRORS -gt 0 ]]; then
  fail "Verification failed: ${ERRORS} error(s), ${WARNINGS} warning(s)"
  exit 1
else
  if [[ $WARNINGS -gt 0 ]]; then
    pass "Verification passed with ${WARNINGS} warning(s)"
  else
    pass "Verification passed"
  fi
  exit 0
fi
