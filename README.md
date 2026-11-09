# rex-resume

[![Claude Code 2.1.292+](https://img.shields.io/badge/Claude%20Code-2.1.292%2B-d97757)](https://code.claude.com)
[![License: MIT](https://img.shields.io/github/license/arihantbansal/rex-resume)](LICENSE)

Restart your computer and your Claude Code conversations come back in the same
[Rex](https://www.superlogical.com/rex) panes.

Rex restores your sessions, tabs, and panes after a restart, but not the
programs that were running in them. rex-resume remembers the Claude Code
conversation in each pane. When Rex restores the pane, it reopens that
conversation, ready for your next message. There's nothing to run after a
restart. It keeps no backup of its own: the conversations come from the history
Claude Code already saves.

## Install

You need Rex, Claude Code 2.1.292 or later, zsh, and jq. macOS 15 and later
include jq; on older systems, install it with your package manager.

Install the plugin, then load its shell integration from `~/.zshrc`:

```sh
claude plugin install rex-resume --marketplace arihantbansal/rex-resume
echo '[[ -r ~/.claude/plugins/marketplaces/rex-resume/rex-resume.zsh ]] && source ~/.claude/plugins/marketplaces/rex-resume/rex-resume.zsh' >> ~/.zshrc
```

Open a new Rex pane, start `claude`, and send a message. A file named after the
pane appears in `~/.local/state/rex-resume/`.

To see a resume without rebooting, run Rex's **Restart Server…** action. It ends
every program running in Rex, the same as a restart would. Quitting the Rex app
isn't a test: the server keeps your panes running while the app is closed.

## How it works

The plugin adds a Claude Code hook. The shell integration adds a prompt hook to
zsh. Together they handle three moments:

| When | What happens |
| --- | --- |
| You start Claude in a Rex pane | The hook saves the conversation ID, its folder, and the shell that started Claude to `~/.local/state/rex-resume/<pane>.json`. |
| You quit Claude | Your prompt returns and Claude is gone, so the file is deleted and the pane won't resume. Suspending Claude with Ctrl+Z keeps the file. |
| Rex restores the pane | The pane's new shell finds a file whose shell no longer exists. It runs `cd <folder> && claude --resume <id>` at its first prompt, as if you had typed it. |

Starting a new conversation with `/clear`, or switching with `/resume`, updates
the file, so the pane reopens the conversation you last had open.

rex-resume ignores:

- Claude running inside [herdr](https://herdr.dev), which resumes its own panes.
- `claude -p` started by another program.
- Subagents.
- Conversations without a message yet, which Claude hasn't saved.

## What it touches

- Reads the `REX_BLOCK`, `CLAUDE_PID`, `CLAUDE_PROJECT_DIR`, and `HERDR_ENV`
  environment variables.
- Runs `ps` to find Claude's terminal, the shell that started it, and when
  that shell started.
- Writes one small JSON file per pane to `~/.local/state/rex-resume/`, or
  `$XDG_STATE_HOME/rex-resume/` when that's set. Nothing leaves your machine.
- Types one command at the first prompt of a pane that Rex restored.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| A conversation didn't come back | Before the restart, the pane had a file in `~/.local/state/rex-resume/`. If it didn't, Claude was started outside Rex or inside herdr, or the conversation had no messages. |
| No file appears when Claude starts | Run `claude plugin list` and check that rex-resume is enabled. |
| Nothing happens when the pane is restored | In a Rex pane, `whence _rex_resume_forget` should print `_rex_resume_forget`. If it doesn't, the line in `~/.zshrc` isn't loading. |
| A pane reopens a conversation you're done with | Quit Claude in that pane with `/exit` or Ctrl+C, and it won't come back. |

## Limitations

- Only Claude Code and zsh are supported.
- Claude resumes with your default settings. Flags from the original launch,
  such as `--model`, aren't repeated.

## Update

To get updates automatically, run `/plugin` in Claude Code, open the
**Marketplaces** tab, select rex-resume, and turn on auto-update. To update by
hand:

```sh
claude plugin marketplace update rex-resume
claude plugin update rex-resume
```

An update applies to shells and Claude sessions you start afterward.

## Turn off or uninstall

`claude plugin disable rex-resume` stops recording new conversations. Panes
recorded before that still reopen after the next restart, because the shell
integration loads separately. To stop those too, delete
`~/.local/state/rex-resume`.

To remove rex-resume completely:

```sh
claude plugin uninstall rex-resume
claude plugin marketplace remove rex-resume
rm -rf ~/.local/state/rex-resume
```

Then remove the `rex-resume.zsh` line from `~/.zshrc`.

## Development

```sh
git clone https://github.com/arihantbansal/rex-resume
cd rex-resume
claude --plugin-dir .
```

`--plugin-dir` loads the hook from your clone for one session. Point the
`source` line in `~/.zshrc` at your clone's `rex-resume.zsh` to test shell
changes. Before opening a pull request, run these from a terminal:

```sh
./test.zsh
shellcheck hooks/session-start.sh
zsh -n rex-resume.zsh
claude plugin validate .
```

`test.zsh` checks recording, forgetting, Ctrl+Z, and restore detection. It
can't drive a live prompt, so also start Claude in a Rex pane, run **Restart
Server…**, and confirm the conversation reopens.

Issues and pull requests are welcome. Support for bash or fish is the most
useful next step.

## Acknowledgments

[herdr](https://herdr.dev) resumes agents by their session IDs after a restart.
rex-resume brings the same idea to Rex.

## License

[MIT](LICENSE)
