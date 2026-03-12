#!/usr/bin/env python3
"""Smoke tests for guard_bash_commands.py.

Runs the guard script with various inputs and verifies it produces
correct allow/deny decisions.
"""

import json
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
GUARD_SCRIPT = os.path.join(REPO_ROOT, "scripts", "guard_bash_commands.py")

ERRORS = 0


def pass_msg(msg: str) -> None:
    print(f"\033[0;32m[pass]\033[0m  {msg}")


def fail_msg(msg: str) -> None:
    global ERRORS
    print(f"\033[0;31m[FAIL]\033[0m  {msg}")
    ERRORS += 1


def run_guard(command: str) -> dict | None:
    """Run the guard script with a simulated PreToolUse payload.
    Returns the parsed JSON output, or None if no output (allow)."""
    payload = {
        "hook_event_name": "PreToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": command},
    }
    result = subprocess.run(
        [sys.executable, GUARD_SCRIPT],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode != 0:
        fail_msg(f"Guard script exited with code {result.returncode} for: {command}")
        return None
    if result.stdout.strip():
        try:
            return json.loads(result.stdout.strip())
        except json.JSONDecodeError:
            fail_msg(f"Guard script produced invalid JSON for: {command}")
            return None
    return None


def is_denied(output: dict | None) -> bool:
    if output is None:
        return False
    hook_output = output.get("hookSpecificOutput", {})
    return hook_output.get("permissionDecision") == "deny"


def test_should_deny(command: str, description: str) -> None:
    output = run_guard(command)
    if is_denied(output):
        pass_msg(f"Denied: {description}")
    else:
        fail_msg(f"Should have denied: {description} — command: {command}")


def test_should_allow(command: str, description: str) -> None:
    output = run_guard(command)
    if not is_denied(output):
        pass_msg(f"Allowed: {description}")
    else:
        reason = (output or {}).get("hookSpecificOutput", {}).get("permissionDecisionReason", "")
        fail_msg(f"Should have allowed: {description} — command: {command} — reason: {reason}")


def main() -> None:
    print("Testing guard_bash_commands.py")
    print("=" * 50)
    print()

    # --- Should deny ---

    print("Commands that should be DENIED:")
    print("-" * 40)

    test_should_deny("git push origin main", "push to main")
    test_should_deny("git push origin master", "push to master")
    test_should_deny("git push origin trunk", "push to trunk")
    test_should_deny("git push origin HEAD:main", "push HEAD to main")
    test_should_deny("git push origin HEAD:master", "push HEAD to master")
    test_should_deny("git push --force origin feature", "force push")
    test_should_deny("git push -f origin feature", "force push short flag")
    test_should_deny("git push --force-with-lease origin feature", "force-with-lease push")
    test_should_deny("git reset --hard", "git reset --hard")
    test_should_deny("git reset --hard HEAD~1", "git reset --hard HEAD~1")
    test_should_deny("rm -rf /", "rm -rf /")
    test_should_deny("rm -rf .git", "rm -rf .git")
    test_should_deny("gh pr merge", "gh pr merge")
    test_should_deny("gh pr merge 123", "gh pr merge with number")
    test_should_deny("gh issue close", "gh issue close")
    test_should_deny("gh issue close 42", "gh issue close with number")

    print()

    # --- Should allow ---

    print("Commands that should be ALLOWED:")
    print("-" * 40)

    test_should_allow("git push origin issue/42-fix-bug", "push to feature branch")
    test_should_allow("git push origin feature/add-tests", "push to feature branch")
    test_should_allow("git push -u origin issue/42-fix-bug", "push with upstream tracking")
    test_should_allow("git status", "git status")
    test_should_allow("git diff", "git diff")
    test_should_allow("git log --oneline -10", "git log")
    test_should_allow("git checkout -b issue/42-fix", "git checkout new branch")
    test_should_allow("git add .", "git add")
    test_should_allow("git commit -m 'Fix #42'", "git commit")
    test_should_allow("gh issue view 42", "gh issue view")
    test_should_allow("gh issue comment 42 --body 'hello'", "gh issue comment")
    test_should_allow("npm test", "npm test")
    test_should_allow("pytest", "pytest")
    test_should_allow("cargo test", "cargo test")
    test_should_allow("make test", "make test")
    test_should_allow("ls -la", "ls")
    test_should_allow("cat README.md", "cat")

    print()

    # --- Non-Bash events should pass through ---

    print("Non-matching events:")
    print("-" * 40)

    # Non-Bash tool
    payload = {
        "hook_event_name": "PreToolUse",
        "tool_name": "Read",
        "tool_input": {"file_path": "/etc/passwd"},
    }
    result = subprocess.run(
        [sys.executable, GUARD_SCRIPT],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode == 0 and not result.stdout.strip():
        pass_msg("Non-Bash tool passes through")
    else:
        fail_msg("Non-Bash tool should pass through silently")

    # Non-PreToolUse event
    payload = {
        "hook_event_name": "PostToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": "git push origin main"},
    }
    result = subprocess.run(
        [sys.executable, GUARD_SCRIPT],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode == 0 and not result.stdout.strip():
        pass_msg("Non-PreToolUse event passes through")
    else:
        fail_msg("Non-PreToolUse event should pass through silently")

    # Malformed input
    result = subprocess.run(
        [sys.executable, GUARD_SCRIPT],
        input="not json",
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode == 0:
        pass_msg("Malformed input fails open")
    else:
        fail_msg("Malformed input should fail open (exit 0)")

    print()

    # --- Summary ---

    print("=" * 50)
    if ERRORS > 0:
        fail_msg(f"Guard script tests failed: {ERRORS} error(s)")
        sys.exit(1)
    else:
        pass_msg("All guard script tests passed")
        sys.exit(0)


if __name__ == "__main__":
    main()
