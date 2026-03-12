#!/usr/bin/env bash
# Smoke test: validate Mimiron repository structure.
# Exit 0 if all checks pass, exit 1 if any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ERRORS=0

pass() { printf "\033[0;32m[pass]\033[0m  %s\n" "$*"; }
fail() { printf "\033[0;31m[FAIL]\033[0m  %s\n" "$*"; ERRORS=$((ERRORS + 1)); }

# --- Required files -------------------------------------------------------

required_files=(
  "plugin.json"
  "VERSION"
  "LICENSE"
  "README.md"
  "CONTRIBUTING.md"
  "CODE_OF_CONDUCT.md"
  "SECURITY.md"
  "CHANGELOG.md"
  "AGENTS.md"
  ".gitignore"
  ".editorconfig"
  ".claude/skills/solve-issue/SKILL.md"
  ".claude/skills/solve-issue/templates/issue-followup-comment.md"
  ".claude/skills/solve-issue/examples/final-response-format.md"
  ".claude/agents/issue-implementer.md"
  ".claude/scripts/guard_bash_commands.py"
  ".agents/skills/solve-issue/SKILL.md"
  ".agents/openai.yaml"
  "install/install.sh"
  "install/uninstall.sh"
  "install/verify.sh"
  "install/install-codex.sh"
  "install/verify-codex.sh"
  "docs/architecture.md"
  "docs/installation.md"
  "docs/usage.md"
  "docs/security-model.md"
  "docs/authoring-guide.md"
  "docs/release-process.md"
)

for f in "${required_files[@]}"; do
  if [[ -f "${REPO_ROOT}/${f}" ]]; then
    pass "Found: ${f}"
  else
    fail "Missing: ${f}"
  fi
done

# --- Required directories -------------------------------------------------

required_dirs=(
  ".claude/skills"
  ".claude/agents"
  ".claude/scripts"
  ".agents/skills"
  "docs"
  "install"
  "tests"
  "tests/smoke"
  "manifests"
)

for d in "${required_dirs[@]}"; do
  if [[ -d "${REPO_ROOT}/${d}" ]]; then
    pass "Directory: ${d}"
  else
    fail "Missing directory: ${d}"
  fi
done

# --- plugin.json is valid JSON -------------------------------------------

if python3 -c "import json; json.load(open('${REPO_ROOT}/plugin.json'))" 2>/dev/null; then
  pass "plugin.json is valid JSON"
else
  fail "plugin.json is not valid JSON"
fi

# --- VERSION matches plugin.json -----------------------------------------

file_version="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
json_version="$(python3 -c "import json; print(json.load(open('${REPO_ROOT}/plugin.json'))['version'])" 2>/dev/null)"

if [[ "$file_version" == "$json_version" ]]; then
  pass "VERSION (${file_version}) matches plugin.json"
else
  fail "VERSION (${file_version}) does not match plugin.json (${json_version})"
fi

# --- YAML frontmatter checks ---------------------------------------------

check_frontmatter() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    if head -1 "$file" | grep -q '^---$'; then
      pass "${label} has YAML frontmatter"
    else
      fail "${label} missing YAML frontmatter"
    fi
  fi
}

check_frontmatter "${REPO_ROOT}/.claude/skills/solve-issue/SKILL.md" "Claude SKILL.md"
check_frontmatter "${REPO_ROOT}/.claude/agents/issue-implementer.md" "issue-implementer.md"
check_frontmatter "${REPO_ROOT}/.agents/skills/solve-issue/SKILL.md" "Codex SKILL.md"

# --- Codex implicit invocation disabled -----------------------------------

codex_config="${REPO_ROOT}/.agents/openai.yaml"
if [[ -f "$codex_config" ]]; then
  if grep -q 'allow_implicit_invocation: false' "$codex_config"; then
    pass "Codex implicit invocation disabled"
  else
    fail "Codex openai.yaml should have allow_implicit_invocation: false"
  fi
fi

# --- Executable bits ------------------------------------------------------

if [[ -x "${REPO_ROOT}/.claude/scripts/guard_bash_commands.py" ]]; then
  pass "guard_bash_commands.py is executable"
else
  fail "guard_bash_commands.py is not executable"
fi

for script in install.sh uninstall.sh verify.sh install-codex.sh verify-codex.sh; do
  if [[ -x "${REPO_ROOT}/install/${script}" ]]; then
    pass "${script} is executable"
  else
    fail "${script} is not executable"
  fi
done

# --- plugin.json references resolve --------------------------------------

if python3 -c "
import json, os, sys
root = '${REPO_ROOT}'
with open(os.path.join(root, 'plugin.json')) as f:
    data = json.load(f)
errors = []
for section in ['skills', 'agents', 'scripts']:
    for entry in data.get(section, []):
        path = entry.get('path', '')
        if not os.path.isfile(os.path.join(root, path)):
            errors.append(path)
if errors:
    for e in errors:
        print(f'MISSING:{e}')
    sys.exit(1)
else:
    print('OK')
    sys.exit(0)
" 2>/dev/null; then
  pass "All plugin.json references are valid"
else
  fail "Some plugin.json references are broken"
fi

# --- Summary --------------------------------------------------------------

echo ""
echo "---"
if [[ $ERRORS -gt 0 ]]; then
  fail "Structure test failed: ${ERRORS} error(s)"
  exit 1
else
  pass "All structure tests passed"
  exit 0
fi
