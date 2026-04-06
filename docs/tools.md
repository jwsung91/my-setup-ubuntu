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
| `zoxide` | Custom | Smarter `cd` command that learns your habits | <https://github.com/ajeetdsouza/zoxide> |
| `tldr` | `tldr` | Simplified and community-driven man pages | <https://tldr.sh/> |
| `lazygit` | Custom | Simple terminal UI for git commands | <https://github.com/jesseduffield/lazygit> |
| `eza` | Custom | Modern replacement for `ls` with icons and git support | <https://github.com/eza-community/eza> |
| `btop` | `btop` | Interactive resource monitor (CPU, memory, etc.) | <https://github.com/aristocratos/btop> |
| `lazydocker` | Custom | Simple terminal UI for docker commands | <https://github.com/jesseduffield/lazydocker> |
| `dust` | Custom | More intuitive version of `du` in Rust | <https://github.com/bootandy/dust> |
| `yazi` | Custom | Blazing fast terminal file manager written in Rust | <https://github.com/sxyazi/yazi> |
| `tmux` | `tmux` | Terminal multiplexer for persistent and split terminal sessions | <https://github.com/tmux/tmux/wiki> |
| `xclip` | `xclip` | Clipboard bridge for X11-based Linux desktops | <https://github.com/astrand/xclip> |

## Notes

- On Ubuntu, `fd` is commonly installed as the `fdfind` binary. This setup creates `~/.local/bin/fd` when needed.
- On Ubuntu, `bat` may be installed as `batcat`. This setup creates `~/.local/bin/bat` when needed.
- `tmux` and `xclip` are optional in the interactive checklist and are disabled by default.
