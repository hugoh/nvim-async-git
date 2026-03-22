# nvim-async-git: Async Git Commands for Neovim

A Neovim plugin that provides a `:Git` command with smart handling - interactive by default, background for network operations.

Heavily inspired by the awesome [vim-fugitive](https://github.com/tpope/vim-fugitive) by tpope.

## Dependencies

- [snacks.nvim](https://github.com/folke/snacks.nvim)

## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "hugoh/nvim-async-git",
  dependencies = { "folke/snacks.nvim" },
}
```

## Usage

### `:Git <command>`

Run any git command with smart handling:

- **Interactive by default** - opens a floating terminal for commands that may need user input
- **Background for network ops** - `push`, `pull`, `fetch`, `clone`, `remote` run asynchronously with notifications

Examples:

- `:Git commit` - Opens terminal for commit message
- `:Git push` - Runs in background, notifies on completion
- `:Git rebase -i HEAD~3` - Opens terminal for interactive rebase

Tab completion provided for git subcommands and file paths.

- `:Git add -p` - Opens terminal for patch staging

### Convenience Commands

- `:Gread [file]` - Replace buffer with HEAD version of file
- `:Gwrite [file]` - Stage current file (or specified file)
