# Developer CLI Tools

This project can install a small set of developer-oriented terminal tools through [`scripts/tools.sh`](/home/rain/workspace/jwsung91/my-setup-ubuntu/scripts/tools.sh).

## Included Tools

| Tool | Package | What it is for | Upstream |
| --- | --- | --- | --- |
| `ripgrep` | `ripgrep` | Fast recursive text search, useful as a modern `grep` replacement | <https://github.com/BurntSushi/ripgrep> |
| `fd` | `fd-find` | Fast file and directory search, useful as a simpler `find` replacement | <https://github.com/sharkdp/fd> |
| `fzf` | `fzf` | Fuzzy finder for files, command history, and custom shell workflows | <https://github.com/junegunn/fzf> |
| `bat` | `bat` | Syntax-highlighted file viewer, useful as a richer `cat` | <https://github.com/sharkdp/bat> |
| `jq` | `jq` | Command-line JSON parser and transformer | <https://jqlang.org/> |
| `tmux` | `tmux` | Terminal multiplexer for persistent and split terminal sessions | <https://github.com/tmux/tmux/wiki> |
| `xclip` | `xclip` | Clipboard bridge for X11-based Linux desktops | <https://github.com/astrand/xclip> |

## Notes

- On Ubuntu, `fd` is commonly installed as the `fdfind` binary. This setup creates `~/.local/bin/fd` when needed.
- On Ubuntu, `bat` may be installed as `batcat`. This setup creates `~/.local/bin/bat` when needed.
- `tmux` and `xclip` are optional in the interactive checklist and are disabled by default.
