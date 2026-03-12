#!/usr/bin/env bash
# Mimiron Codex installer — installs Codex skill placeholders.
#
# Usage:
#   install-codex.sh --target <path> [--mode copy|symlink] [--dry-run]

set -euo pipefail

PACK_NAME="mimiron-codex"
VERSION=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Files to install: source (relative to SOURCE_ROOT) -> target (relative to target .agents/)
declare -a INSTALL_MAP=(
  ".agents/skills/solve-issue/SKILL.md|skills/solve-issue/SKILL.md"
  ".agents/openai.yaml|openai.yaml"
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
  install-codex.sh --target <path> [--mode copy|symlink] [--dry-run] [--force]

Options:
  --target <path>   Target directory (e.g., $CODEX_HOME or ~/.codex)
  --mode <mode>     "copy" or "symlink" (default: copy)
  --dry-run         Show what would happen without making changes
  --force           Allow overwriting existing files (backups are still created)
  -h, --help        Show this help
USAGE
  exit 0
}

# --- Parse arguments ------------------------------------------------------

TARGET=""
MODE="copy"
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --mode)    MODE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    -h|--help) usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -z "$TARGET" ]] && die "--target is required"
[[ "$MODE" == "copy" || "$MODE" == "symlink" ]] || die "Mode must be 'copy' or 'symlink', got: $MODE"

if [[ -f "${SOURCE_ROOT}/VERSION" ]]; then
  VERSION="$(tr -d '[:space:]' < "${SOURCE_ROOT}/VERSION")"
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || die "Target directory does not exist: $TARGET"
AGENTS_DIR="${TARGET}/.agents"

info "Mimiron Codex installer v${VERSION}"
info "Source:  ${SOURCE_ROOT}"
info "Target:  ${AGENTS_DIR}"
info "Mode:    ${MODE}"
[[ "$DRY_RUN" == true ]] && info "DRY RUN — no changes will be made"
echo ""

# Verify source
for entry in "${INSTALL_MAP[@]}"; do
  src="${entry%%|*}"
  [[ -f "${SOURCE_ROOT}/${src}" ]] || die "Source file missing: ${SOURCE_ROOT}/${src}"
done

# Install
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
MANIFEST_DIR="${AGENTS_DIR}/.mimiron"
MANIFEST_FILE="${MANIFEST_DIR}/manifest.json"

declare -a INSTALLED_FILES=()
declare -a CREATED_DIRS=()
declare -a BACKUPS=()

for entry in "${INSTALL_MAP[@]}"; do
  src_rel="${entry%%|*}"
  tgt_rel="${entry##*|}"
  src_path="${SOURCE_ROOT}/${src_rel}"
  tgt_path="${AGENTS_DIR}/${tgt_rel}"
  tgt_dir="$(dirname "$tgt_path")"

  if [[ ! -d "$tgt_dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "Would create directory: ${tgt_dir}"
    else
      mkdir -p "$tgt_dir"
      CREATED_DIRS+=("$tgt_dir")
      info "Created directory: ${tgt_dir}"
    fi
  fi

  if [[ -e "$tgt_path" || -L "$tgt_path" ]]; then
    if [[ "$FORCE" != true ]]; then
      die "Target exists: ${tgt_path} — use --force to overwrite"
    fi
    backup_path="${tgt_path}.mimiron-backup.${TIMESTAMP}"
    if [[ "$DRY_RUN" == true ]]; then
      info "Would backup: ${tgt_path} -> ${backup_path}"
    else
      cp -a "$tgt_path" "$backup_path" 2>/dev/null || mv "$tgt_path" "$backup_path"
      BACKUPS+=("${tgt_rel}|${backup_path}")
      info "Backed up: ${tgt_path} -> ${backup_path}"
    fi
  fi

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
done

# Write manifest
if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "$MANIFEST_DIR"

  files_json="["
  first=true
  for f in "${INSTALLED_FILES[@]}"; do
    if [[ "$first" == true ]]; then first=false; else files_json+=","; fi
    files_json+="\"${f}\""
  done
  files_json+="]"

  dirs_json="["
  first=true
  for d in "${CREATED_DIRS[@]}"; do
    if [[ "$first" == true ]]; then first=false; else dirs_json+=","; fi
    dirs_json+="\"${d}\""
  done
  dirs_json+="]"

  backups_json="["
  first=true
  for b in "${BACKUPS[@]}"; do
    if [[ "$first" == true ]]; then first=false; else backups_json+=","; fi
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
  "agents_dir": "${AGENTS_DIR}",
  "install_mode": "${MODE}",
  "files": ${files_json},
  "directories_created": ${dirs_json},
  "backups": ${backups_json},
  "verified": false
}
MANIFEST

  ok "Manifest written: ${MANIFEST_FILE}"
fi

echo ""
if [[ "$DRY_RUN" == true ]]; then
  info "Dry run complete. No changes were made."
else
  ok "Mimiron Codex placeholders v${VERSION} installed to ${AGENTS_DIR}"
  info "Note: Codex skills are placeholders only — not yet functional."
fi
