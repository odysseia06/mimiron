#!/usr/bin/env bash
# Mimiron installer — optional convenience script for manual setup.
# The primary install path is: claude plugin add github:mimiron-dev/mimiron
#
# Usage:
#   install.sh --target <path> --scope project [--mode copy|symlink] [--dry-run]
#   install.sh --scope user [--mode copy|symlink] [--dry-run]

set -euo pipefail

# --- Constants -----------------------------------------------------------

PACK_NAME="mimiron"
VERSION=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Files to install: source (relative to SOURCE_ROOT) -> target (relative to .claude/)
declare -a INSTALL_MAP=(
  "skills/solve-issue/SKILL.md|skills/solve-issue/SKILL.md"
  "skills/solve-issue/templates/issue-followup-comment.md|skills/solve-issue/templates/issue-followup-comment.md"
  "skills/solve-issue/examples/final-response-format.md|skills/solve-issue/examples/final-response-format.md"
  "agents/issue-implementer.md|agents/issue-implementer.md"
  "scripts/guard_bash_commands.py|scripts/guard_bash_commands.py"
)

# Files that need executable bit
declare -a EXECUTABLES=(
  "scripts/guard_bash_commands.py"
)

# --- Helpers --------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[info]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[error]${NC} %s\n" "$*" >&2; }
die()   { err "$@"; exit 1; }

usage() {
  cat <<'USAGE'
Usage:
  install.sh --target <path> --scope project [--mode copy|symlink] [--dry-run]
  install.sh --scope user [--mode copy|symlink] [--dry-run]

Options:
  --target <path>   Target project or user directory
  --scope <scope>   "project" or "user" (default: project)
  --mode <mode>     "copy" or "symlink" (default: copy)
  --dry-run         Show what would happen without making changes
  --force           Allow overwriting existing files (backups are still created)
  -h, --help        Show this help
USAGE
  exit 0
}

# --- Parse arguments ------------------------------------------------------

TARGET=""
SCOPE="project"
MODE="copy"
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --scope)   SCOPE="$2"; shift 2 ;;
    --mode)    MODE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    -h|--help) usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

# --- Validate inputs ------------------------------------------------------

[[ "$SCOPE" == "project" || "$SCOPE" == "user" ]] || die "Scope must be 'project' or 'user', got: $SCOPE"
[[ "$MODE" == "copy" || "$MODE" == "symlink" ]] || die "Mode must be 'copy' or 'symlink', got: $MODE"

# Read version
if [[ -f "${SOURCE_ROOT}/VERSION" ]]; then
  VERSION="$(tr -d '[:space:]' < "${SOURCE_ROOT}/VERSION")"
fi

# Determine target root
if [[ "$SCOPE" == "user" ]]; then
  TARGET="${TARGET:-${HOME}}"
  CLAUDE_DIR="${TARGET}/.claude"
elif [[ -z "$TARGET" ]]; then
  die "--target is required for project scope"
else
  CLAUDE_DIR="${TARGET}/.claude"
fi

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || die "Target directory does not exist: $TARGET"
CLAUDE_DIR="${TARGET}/.claude"

info "Mimiron installer v${VERSION}"
info "Source:  ${SOURCE_ROOT}"
info "Target:  ${CLAUDE_DIR}"
info "Scope:   ${SCOPE}"
info "Mode:    ${MODE}"
[[ "$DRY_RUN" == true ]] && info "DRY RUN — no changes will be made"
echo ""

# --- Verify source --------------------------------------------------------

for entry in "${INSTALL_MAP[@]}"; do
  src="${entry%%|*}"
  [[ -f "${SOURCE_ROOT}/${src}" ]] || die "Source file missing: ${SOURCE_ROOT}/${src}"
done

# --- Install files --------------------------------------------------------

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
MANIFEST_DIR="${CLAUDE_DIR}/.mimiron"
MANIFEST_FILE="${MANIFEST_DIR}/manifest.json"

declare -a INSTALLED_FILES=()
declare -a CREATED_DIRS=()
declare -a BACKUPS=()

install_file() {
  local src_rel="$1"
  local tgt_rel="$2"
  local src_path="${SOURCE_ROOT}/${src_rel}"
  local tgt_path="${CLAUDE_DIR}/${tgt_rel}"
  local tgt_dir
  tgt_dir="$(dirname "$tgt_path")"

  # Create target directory
  if [[ ! -d "$tgt_dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "Would create directory: ${tgt_dir}"
    else
      mkdir -p "$tgt_dir"
      CREATED_DIRS+=("$tgt_dir")
      info "Created directory: ${tgt_dir}"
    fi
  fi

  # Handle existing file
  if [[ -e "$tgt_path" || -L "$tgt_path" ]]; then
    if [[ "$FORCE" != true ]]; then
      die "Target exists: ${tgt_path} — use --force to overwrite (backup will be created)"
    fi
    local backup_path="${tgt_path}.mimiron-backup.${TIMESTAMP}"
    if [[ "$DRY_RUN" == true ]]; then
      info "Would backup: ${tgt_path} -> ${backup_path}"
    else
      cp -a "$tgt_path" "$backup_path" 2>/dev/null || mv "$tgt_path" "$backup_path"
      BACKUPS+=("${tgt_rel}|${backup_path}")
      info "Backed up: ${tgt_path} -> ${backup_path}"
    fi
  fi

  # Install
  if [[ "$MODE" == "symlink" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "Would symlink: ${tgt_path} -> ${src_path}"
    else
      ln -sf "$src_path" "$tgt_path"
      ok "Symlinked: ${tgt_path} -> ${src_path}"
    fi
  else
    if [[ "$DRY_RUN" == true ]]; then
      info "Would copy: ${src_path} -> ${tgt_path}"
    else
      cp "$src_path" "$tgt_path"
      ok "Copied: ${src_path} -> ${tgt_path}"
    fi
  fi

  INSTALLED_FILES+=("$tgt_rel")
}

# Install each file
for entry in "${INSTALL_MAP[@]}"; do
  src_rel="${entry%%|*}"
  tgt_rel="${entry##*|}"
  install_file "$src_rel" "$tgt_rel"
done

# Set executable bits
for exe in "${EXECUTABLES[@]}"; do
  tgt_path="${CLAUDE_DIR}/${exe}"
  if [[ -f "$tgt_path" ]] && [[ "$DRY_RUN" != true ]]; then
    chmod +x "$tgt_path"
  fi
done

# --- Write manifest -------------------------------------------------------

if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "$MANIFEST_DIR"

  # Build JSON manifest
  files_json="["
  first=true
  for f in "${INSTALLED_FILES[@]}"; do
    [[ "$first" == true ]] && first=false || files_json+=","
    files_json+="\"${f}\""
  done
  files_json+="]"

  dirs_json="["
  first=true
  for d in "${CREATED_DIRS[@]}"; do
    [[ "$first" == true ]] && first=false || dirs_json+=","
    dirs_json+="\"${d}\""
  done
  dirs_json+="]"

  backups_json="["
  first=true
  for b in "${BACKUPS[@]}"; do
    [[ "$first" == true ]] && first=false || backups_json+=","
    local_rel="${b%%|*}"
    local_path="${b##*|}"
    backups_json+="{\"file\":\"${local_rel}\",\"backup\":\"${local_path}\"}"
  done
  backups_json+="]"

  cat > "$MANIFEST_FILE" <<MANIFEST
{
  "pack": "${PACK_NAME}",
  "version": "${VERSION}",
  "installed_at": "${TIMESTAMP}",
  "source_root": "${SOURCE_ROOT}",
  "target_root": "${TARGET}",
  "claude_dir": "${CLAUDE_DIR}",
  "install_mode": "${MODE}",
  "install_scope": "${SCOPE}",
  "files": ${files_json},
  "directories_created": ${dirs_json},
  "backups": ${backups_json},
  "verified": false
}
MANIFEST

  ok "Manifest written: ${MANIFEST_FILE}"
fi

# --- Summary --------------------------------------------------------------

echo ""
if [[ "$DRY_RUN" == true ]]; then
  info "Dry run complete. No changes were made."
  info "Run without --dry-run to install."
else
  ok "Mimiron v${VERSION} installed to ${CLAUDE_DIR}"
  info "Verify with: bash install/verify.sh --target ${TARGET}"
  info "Uninstall with: bash install/uninstall.sh --target ${TARGET}"
fi
