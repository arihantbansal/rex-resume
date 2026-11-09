#!/bin/sh
# Claude Code SessionStart hook. Records which conversation runs in this Rex
# pane so rex-resume.zsh can resume it after Rex restores the pane.
# It prints nothing, because Claude adds this hook's output to the conversation.

[ -n "${REX_BLOCK:-}" ] && [ -n "${CLAUDE_PID:-}" ] || exit 0
# herdr passes the Rex pane ID on to every pane inside it, so it would be wrong.
[ "${HERDR_ENV:-}" = 1 ] && exit 0

# A Claude started by another program, such as `claude -p` from a tool, has no
# terminal and isn't the conversation in this pane.
case $(ps -o tty= -p "$CLAUDE_PID" | tr -d ' ') in '' | '?' | '??') exit 0 ;; esac
shell=$(ps -o ppid= -p "$CLAUDE_PID" | tr -d ' ')

dir=${XDG_STATE_HOME:-$HOME/.local/state}/rex-resume
file=$dir/${REX_BLOCK#block:}.json
mkdir -p "$dir" || exit 0

# Subagents carry an agent_id and belong to the conversation that started them.
jq -c \
  --argjson claude "$CLAUDE_PID" \
  --argjson shell "$shell" \
  --arg started "$(ps -o lstart= -p "$shell")" \
  --arg dir "${CLAUDE_PROJECT_DIR:-}" \
  'select(.session_id and (.agent_id | not)) | {
    session_id,
    transcript_path,
    dir: (if $dir == "" then .cwd else $dir end),
    claude_pid: $claude,
    shell_pid: $shell,
    shell_started: ($started | gsub("\\s"; ""))
  }' >"$file.$$" && [ -s "$file.$$" ] && mv "$file.$$" "$file"
rm -f "$file.$$"
