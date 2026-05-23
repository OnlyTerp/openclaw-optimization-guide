#!/usr/bin/env bash
# Hook 7: auto-formatter
# Runs the appropriate code formatter on files the agent writes.
# Never blocks — formatters may not be installed. Always exits 0.
path="${OPENCLAW_TOOL_ARGS_PATH:-}"
[ -z "$path" ] && exit 0

case "$path" in
  *.py)              command -v ruff       >/dev/null 2>&1 && ruff format "$path"       >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js)   command -v prettier   >/dev/null 2>&1 && prettier -w "$path"       >/dev/null 2>&1 ;;
  *.go)              command -v gofmt      >/dev/null 2>&1 && gofmt -w "$path"          >/dev/null 2>&1 ;;
  *.rs)              command -v rustfmt    >/dev/null 2>&1 && rustfmt "$path"           >/dev/null 2>&1 ;;
  *.md)              command -v markdownlint-cli2 >/dev/null 2>&1 && markdownlint-cli2 --fix "$path" >/dev/null 2>&1 ;;
esac
exit 0
