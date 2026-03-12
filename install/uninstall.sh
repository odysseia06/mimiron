#!/usr/bin/env bash
# Mimiron uninstaller — removes only what Mimiron installed.
#
# Usage:
#   uninstall.sh --target <path> [--dry-run]
#   uninstall.sh --scope user [--dry-run]

set -euo pipefail

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
  uninstall.sh --target <path> [--dry-run]
  uninstall.sh --scope user [--dry-run]

Options:
  --target <path>   Target project directory
  --scope <scope>   "project" or "user" (default: project)
  --dry-run         Show what would happen without making changes
  -h, --help        Show this help
USAGE
  exit 0
}

# --- Parse arguments ------------------------------------------------------

TARGET=""
SCOPE="project"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --scope)   SCOPE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

# --- Resolve target -------------------------------------------------------

if [[ "$SCOPE" == "user" ]]; then
  TARGET="${TARGET:-${HOME}}"
elif [[ -z "$TARGET" ]]; then
  die "--target is required for project scope"
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || die "Target directory does not exist: $TARGET"
CLAUDE_DIR="${TARGET}/.claude"
MANIFEST_DIR="${CLAUDE_DIR}/.mimiron"
MANIFEST_FILE="${MANIFEST_DIR}/manifest.json"

info "Mimiron uninstaller"
info "Target: ${CLAUDE_DIR}"
[[ "$DRY_RUN" == true ]] && info "DRY RUN — no changes will be made"
echo ""

# --- Read manifest --------------------------------------------------------

if [[ ! -f "$MANIFEST_FILE" ]]; then
  die "No install manifest found at ${MANIFEST_FILE}. Was Mimiron installed here?"
fi

# Simple JSON field extraction (no jq dependency)
extract_json_array() {
  local key="$1"
  local file="$2"
  python3 -c "
import json, sys
with open('${file}') as f:
    data = json.load(f)
items = data.get('${key}', [])
for item in items:
    if isinstance(item, str):
        print(item)
    elif isinstance(item, dict):
        print(json.dumps(item))
"
}

extract_json_field() {
  local key="$1"
  local file="$2"
  python3 -c "
import json
with open('${file}') as f:
    data = json.load(f)
print(data.get('${key}', ''))
"
}

PACK_NAME="$(extract_json_field "pack" "$MANIFEST_FILE")"
VERSION="$(extract_json_field "version" "$MANIFEST_FILE")"

info "Uninstalling ${PACK_NAME} v${VERSION}"
echo ""

# --- Remove installed files -----------------------------------------------

while IFS= read -r rel_path; do
  [[ -z "$rel_path" ]] && continue
  full_path="${CLAUDE_DIR}/${rel_path}"
  if [[ -e "$full_path" || -L "$full_path" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      info "Would remove: ${full_path}"
    else
      rm -f "$full_path"
      ok "Removed: ${full_path}"
    fi
  else
    warn "Already absent: ${full_path}"
  fi
done < <(extract_json_array "files" "$MANIFEST_FILE")

# --- Restore backups ------------------------------------------------------

while IFS= read -r backup_json; do
  [[ -z "$backup_json" ]] && continue
  # Parse backup entry
  backup_file="$(echo "$backup_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file',''))")"
  backup_path="$(echo "$backup_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('backup',''))")"

  if [[ -n "$backup_path" && -e "$backup_path" ]]; then
    target_path="${CLAUDE_DIR}/${backup_file}"
    if [[ "$DRY_RUN" == true ]]; then
      info "Would restore backup: ${backup_path} -> ${target_path}"
    else
      mv "$backup_path" "$target_path"
      ok "Restored backup: ${target_path}"
    fi
  fi
done < <(extract_json_array "backups" "$MANIFEST_FILE")

# --- Remove empty directories (deepest first) ----------------------------

# Collect directories that were created, sort by depth (deepest first)
declare -a dirs_to_check=()
while IFS= read -r dir_path; do
  [[ -z "$dir_path" ]] && continue
  dirs_to_check+=("$dir_path")
done < <(extract_json_array "directories_created" "$MANIFEST_FILE")

# Also check standard Mimiron directories under .claude/
for check_dir in \
  "${CLAUDE_DIR}/skills/solve-issue/examples" \
  "${CLAUDE_DIR}/skills/solve-issue/templates" \
  "${CLAUDE_DIR}/skills/solve-issue" \
  "${CLAUDE_DIR}/skills" \
  "${CLAUDE_DIR}/agents" \
  "${CLAUDE_DIR}/scripts"; do
  dirs_to_check+=("$check_dir")
done

# Deduplicate and sort by path length (deepest first)
printf '%s\n' "${dirs_to_check[@]}" | sort -u -r | while IFS= read -r dir_path; do
  [[ -z "$dir_path" ]] && continue
  if [[ -d "$dir_path" ]]; then
    # Only remove if empty
    if [[ -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        info "Would remove empty directory: ${dir_path}"
      else
        rmdir "$dir_path" 2>/dev/null && ok "Removed empty directory: ${dir_path}" || true
      fi
    fi
  fi
done

# --- Remove manifest ------------------------------------------------------

if [[ "$DRY_RUN" == true ]]; then
  info "Would remove manifest: ${MANIFEST_FILE}"
  info "Would remove manifest directory: ${MANIFEST_DIR}"
else
  rm -f "$MANIFEST_FILE"
  rmdir "$MANIFEST_DIR" 2>/dev/null || true
  ok "Removed manifest"
fi

# --- Summary --------------------------------------------------------------

echo ""
if [[ "$DRY_RUN" == true ]]; then
  info "Dry run complete. No changes were made."
  info "Run without --dry-run to uninstall."
else
  ok "Mimiron uninstalled from ${CLAUDE_DIR}"
fi
