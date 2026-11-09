#!/usr/bin/env zsh
# Checks hooks/session-start.sh and rex-resume.zsh. Run it from a terminal,
# because the hook only records a Claude process that has one.

cd ${0:A:h}
if [[ $(ps -o tty= -p $$) == *'?'* ]]; then
  print 'Run this from a terminal.' >&2
  exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf $tmp' EXIT
export XDG_STATE_HOME=$tmp REX_BLOCK=block:test
unset HERDR_ENV CLAUDE_PID CLAUDE_PROJECT_DIR
record=$tmp/rex-resume/test.json
id=0b8e2c1a-1111-2222-3333-444455556666
failures=0

check() {
  local name=$1
  shift
  if "$@"; then print "ok    $name"; else print "FAIL  $name"; (( failures++ )); fi
}

hook() {
  print -r -- "{\"session_id\":\"${2:-$id}\",\"cwd\":\"$tmp\"$3}" |
    CLAUDE_PID=$1 sh hooks/session-start.sh
}

# Writes a record for a Claude process and the shell that started it.
write_record() {
  mkdir -p ${record:h}
  jq -n --arg session ${3:-$id} --arg dir $tmp --arg transcript $tmp/t.jsonl \
    --argjson claude $1 --argjson shell $2 \
    --arg started "${${$(ps -o lstart= -p $2)//[[:space:]]/}:-gone}" \
    '{session_id: $session, transcript_path: $transcript, dir: $dir,
      claude_pid: $claude, shell_pid: $shell, shell_started: $started}' >$record
}

# The resume command a new shell in this pane would run.
resume_command() { source ./rex-resume.zsh 2>/dev/null; print -r -- $_rex_resume_command }

sleep 0 &
dead=$!
wait $dead
touch $tmp/t.jsonl

hook $$
check 'hook records a Claude that has a terminal' test -f $record
check 'hook saves the Claude process' test "$(jq .claude_pid $record)" = $$
rm -f $record
hook 1
check 'hook skips a Claude without a terminal' test ! -e $record
HERDR_ENV=1 hook $$
check 'hook skips Claude inside herdr' test ! -e $record
hook $$ $id ',"agent_id":"a1"'
check 'hook skips subagents' test ! -e $record

write_record $dead $$
(source ./rex-resume.zsh; _rex_resume_forget)
check 'quitting Claude forgets the conversation' test ! -e $record
sleep 30 &
suspended=$!
write_record $suspended $$
(source ./rex-resume.zsh; _rex_resume_forget)
check 'suspending Claude keeps the conversation' test -e $record
kill $suspended

write_record $dead $$
check 'a running launch shell means no restore' test -z "$(resume_command)"
write_record $dead $dead
check 'a restored pane resumes its conversation' \
  test "$(resume_command)" = "cd ${(q)tmp} && claude --resume $id"
write_record $dead $dead 'not-an-id;'
check 'a broken record is dropped' test -z "$(resume_command)" -a ! -e $record

(( failures == 0 ))
