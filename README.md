# rex-resume

Automatically reopen Claude Code conversations in their
[Rex](https://www.superlogical.com/rex) panes after a reboot or server restart.

Rex restores your panes. rex-resume remembers which conversation belongs in
each one and runs `claude --resume` when it returns.

## Install

Requires Rex, Claude Code 2.1.292+, zsh, and jq.

Install the plugin:

```sh
claude plugin install rex-resume --marketplace arihantbansal/rex-resume
```

Add this line to the end of `~/.zshrc`:

```zsh
[[ -r ~/.claude/plugins/marketplaces/rex-resume/rex-resume.zsh ]] && source ~/.claude/plugins/marketplaces/rex-resume/rex-resume.zsh
```

Open a new Rex pane to load the shell integration.

## Try it

Start `claude` in the new pane and send a message. Run **Restart Server…** from
Rex's command palette. Your conversation should reopen automatically.

This stops programs running directly in Rex panes. Cmd+Q only closes the app;
the server and its programs keep running.

## Behavior

A Claude Code hook records the conversation ID and working directory for each
Rex pane. The shell integration reopens it when Rex restores that pane. Exiting
Claude with `/exit` clears the record.

- Supports interactive Claude Code sessions in zsh.
- Original launch flags, such as `--model`, aren't replayed.
- Claude sessions inside herdr are left to herdr.

Records live in `~/.local/state/rex-resume/`, or `$XDG_STATE_HOME/rex-resume/`
when set. Conversations remain in Claude Code's existing history.

If recovery doesn't work, check that `claude plugin list` shows rex-resume
enabled. In a Rex pane, `whence _rex_resume_forget` should print the function's
name; otherwise, check the source line in `~/.zshrc`.

## Update

```sh
claude plugin marketplace update rex-resume
claude plugin update rex-resume
```

An update applies to shells and Claude sessions you start afterward.

## Turn off or uninstall

To turn off recovery, comment out the source line in `~/.zshrc` and run
`claude plugin disable rex-resume`. Disabling the plugin alone stops new
records; existing records can still resume through the shell integration.

To uninstall, remove the source line and run:

```sh
claude plugin uninstall rex-resume
claude plugin marketplace remove rex-resume
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/rex-resume"
```

## Development

From a clone, run `claude --plugin-dir .` and point the source line in
`~/.zshrc` at your clone's `rex-resume.zsh`. Run checks from a terminal:

```sh
./test.zsh
shellcheck hooks/session-start.sh
zsh -n rex-resume.zsh
claude plugin validate .
```

Use the restart test above to check recovery in a live pane.

Inspired by [herdr](https://herdr.dev)'s session recovery. [MIT](LICENSE).
