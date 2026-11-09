# rex-resume: reopen Claude Code conversations in Rex panes that Rex restored.
# Source this file from ~/.zshrc. hooks/session-start.sh records the conversations.

[[ -n $REX_BLOCK && $HERDR_ENV != 1 ]] && (( $+commands[jq] )) || return 0

typeset -g _rex_resume_file=${XDG_STATE_HOME:-$HOME/.local/state}/rex-resume/${REX_BLOCK#block:}.json

# You quit Claude and this shell's prompt came back, so forget the conversation.
_rex_resume_forget() {
  [[ -f $_rex_resume_file && $(jq -r .shell_pid $_rex_resume_file) == $$ ]] &&
    rm -f $_rex_resume_file
}

# Run the resume command at the first prompt, as if you had typed it.
_rex_resume_run() {
  add-zle-hook-widget -d line-init _rex_resume_run
  BUFFER=$_rex_resume_command
  zle accept-line
}

autoload -Uz add-zsh-hook add-zle-hook-widget
add-zsh-hook precmd _rex_resume_forget

() {
  [[ -f $_rex_resume_file ]] || return 0
  local session transcript dir shell started
  { read -r session; read -r transcript; read -r dir; read -r shell; read -r started } < <(
    jq -r '.session_id, .transcript_path, .dir, .shell_pid, .shell_started' $_rex_resume_file)

  # The shell that started Claude is still running, so Rex didn't restore this pane.
  [[ ${$(ps -o lstart= -p $shell)//[[:space:]]/} == $started ]] && return 0
  # Claude saves nothing before the first message, and the folder may be gone.
  if [[ ! -f $transcript || ! -d $dir ]]; then
    rm -f $_rex_resume_file
    return 0
  fi

  typeset -g _rex_resume_command="cd ${(q)dir} && claude --resume $session"
  zle -N _rex_resume_run
  add-zle-hook-widget line-init _rex_resume_run
}
