#!/usr/bin/env bash
# Mimiron Codex verification script — validates Codex placeholder structure.
#
# Usage:
#   verify-codex.sh --source <mimiron-repo-root>
#   verify-codex.sh --target <installed-target-root>

set -euo pipefail

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
  verify-codex.sh --source <mimiron-repo-root>
  verify-codex.sh --target <installed-target-root>

Options:
  --source <path>   Path to the Mimiron repo root
  --target <path>   Path to an installed Codex target
  -h, --help        Show this help
USAGE
  exit 0
}

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

if [[ -n "$SOURCE" ]]; then
  root="$(cd "$SOURCE" && pwd)"
  info "Verifying Codex source structure: ${root}"
  echo ""

  # Expected Codex files
  for f in ".agents/skills/solve-issue/SKILL.md" ".agents/openai.yaml"; do
    if [[ -f "${root}/${f}" ]]; then
      pass "Found: ${f}"
    else
      fail "Missing: ${f}"
    fi
  done

  # AGENTS.md
  if [[ -f "${root}/AGENTS.md" ]]; then
    pass "Found: AGENTS.md"
  else
    fail "Missing: AGENTS.md"
  fi

  # Codex SKILL.md frontmatter
  local_skill="${root}/.agents/skills/solve-issue/SKILL.md"
  if [[ -f "$local_skill" ]]; then
    if head -1 "$local_skill" | grep -q '^---$'; then
      pass "Codex SKILL.md has YAML frontmatter"
    else
      fail "Codex SKILL.md missing YAML frontmatter"
    fi
  fi

  # Implicit invocation disabled
  local_config="${root}/.agents/openai.yaml"
  if [[ -f "$local_config" ]]; then
    if grep -q 'allow_implicit_invocation: false' "$local_config"; then
      pass "Codex implicit invocation disabled"
    else
      fail "openai.yaml should have allow_implicit_invocation: false"
    fi
  fi
fi

if [[ -n "$TARGET" ]]; then
  root="$(cd "$TARGET" && pwd)"
  agents_dir="${root}/.agents"
  info "Verifying Codex installation: ${agents_dir}"
  echo ""

  if [[ ! -d "$agents_dir" ]]; then
    fail "No .agents directory found at ${agents_dir}"
  else
    for f in "skills/solve-issue/SKILL.md" "openai.yaml"; do
      full="${agents_dir}/${f}"
      if [[ -e "$full" || -L "$full" ]]; then
        pass "Found: .agents/${f}"
      else
        fail "Missing: .agents/${f}"
      fi
    done
  fi
fi

echo ""
echo "---"
if [[ $ERRORS -gt 0 ]]; then
  fail "Codex verification failed: ${ERRORS} error(s), ${WARNINGS} warning(s)"
  exit 1
else
  if [[ $WARNINGS -gt 0 ]]; then
    pass "Codex verification passed with ${WARNINGS} warning(s)"
  else
    pass "Codex verification passed"
  fi
  exit 0
fi
