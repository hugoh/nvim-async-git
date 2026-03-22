# nvim-async-git: Async Git Commands for Neovim

A Neovim plugin that provides a simple `:Git` command with completion and backgrounding for network operations.

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

Tab completion provided for git subcommands and file paths.

Run any git command with smart handling:

- **Interactive by default** - opens a floating terminal for commands that may need user input
- **Background for network ops** - `push`, `pull`, `fetch`, `clone`, `remote` run asynchronously with notifications

### Convenience Commands

- `:Gread [file]` - Replace buffer with HEAD version of file
- `:Gwrite [file]` - Stage current file (or specified file)
