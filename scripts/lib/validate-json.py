#!/usr/bin/env python3
"""Validate that every path passed on the command line parses as JSON."""
import json
import sys


def main(paths: list[str]) -> int:
    failed = False
    for path in paths:
        try:
            with open(path) as f:
                json.load(f)
        except FileNotFoundError:
            print(f"MISSING: {path}", file=sys.stderr)
            failed = True
        except json.JSONDecodeError as e:
            print(f"INVALID: {path}: {e}", file=sys.stderr)
            failed = True
        else:
            print(f"OK: {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
