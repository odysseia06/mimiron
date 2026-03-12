#!/usr/bin/env python3

import json
import re
import sys


def deny(reason: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    sys.exit(0)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Fail open rather than breaking the session on malformed input.
        sys.exit(0)

    if payload.get("hook_event_name") != "PreToolUse":
        sys.exit(0)

    if payload.get("tool_name") != "Bash":
        sys.exit(0)

    tool_input = payload.get("tool_input") or {}
    command = (tool_input.get("command") or "").strip()
    if not command:
        sys.exit(0)

    normalized = " ".join(command.split())

    protected_branch_push_patterns = [
        r"(^|\s)git\s+push\s+origin\s+(main|master|trunk)(\s|$)",
        r"(^|\s)git\s+push\s+origin\s+HEAD:(main|master|trunk)(\s|$)",
        r"(^|\s)git\s+push\b.*:(main|master|trunk)(\s|$)",
    ]

    force_push_patterns = [
        r"(^|\s)git\s+push\b.*\s(--force|-f|--force-with-lease)(\s|$)",
    ]

    destructive_patterns = [
        r"(^|\s)git\s+reset\s+--hard(\s|$)",
        r"(^|\s)git\s+clean\b.*-f.*-d.*-x",
        r"(^|\s)rm\s+-rf\s+/(\s|$)",
        r"(^|\s)rm\s+-rf\s+\.git(\s|$)",
    ]

    out_of_scope_patterns = [
        r"(^|\s)gh\s+pr\s+merge(\s|$)",
        r"(^|\s)gh\s+issue\s+close(\s|$)",
    ]

    for pattern in protected_branch_push_patterns:
        if re.search(pattern, normalized, re.IGNORECASE):
            deny("Direct pushes to the default branch are forbidden for this workflow. Push a dedicated issue branch instead.")

    for pattern in force_push_patterns:
        if re.search(pattern, normalized, re.IGNORECASE):
            deny("Force-push is forbidden for this workflow.")

    for pattern in destructive_patterns:
        if re.search(pattern, normalized, re.IGNORECASE):
            deny("Destructive bash command blocked by workflow guard.")

    for pattern in out_of_scope_patterns:
        if re.search(pattern, normalized, re.IGNORECASE):
            deny("This workflow may implement, validate, commit, push a feature branch, and optionally comment on the issue. It must not merge PRs or close issues.")

    # Allow by producing no output and exiting 0.
    sys.exit(0)


if __name__ == "__main__":
    main()
