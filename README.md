# nvim-async-git: Async Git Pull / Push for Neovim

A tiny Neovim plugin that provides async Git push/pull with notifications.

## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{ "hugoh/nvim-async-git" }
```

Using Packer:
```lua
use "hugoh/nvim-async-git"
```

## Usage

Two simple commands:
- `:GitPull` - Async pull with success/failure notifications
- `:GitPush` - Async push with success/failure notifications

No configuration needed - just run the commands in any Git repository.
