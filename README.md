# ✨ yasp.nvim

yasp is a simple way to manage your snippets in a completion engine agnostic
way. Thus it enables you to use jump around completion frameworks and snippet
engines like `mini.snippets` with ease, even native autocompletion for the
nightly users.

The plugin is designed to manage multiple snippet sources such as
friendly-snippets and user defined. It shall be noted that yasp manages only
LSP/vscode/json snippets, therefore fancy lua snippets are not supported. At
last, you must configure some basic functionality for yourself, mainly the
`package.json` paths.

![2025-02-08T17-57-48](https://github.com/user-attachments/assets/40b566b6-0fe2-4b91-b5ea-fa2cbfa8b1f0)


## ⚒️ Configuration

Here is some example configuration, for `lazy.nvim`, please note that the user
has to specify some options in order to use it:

```lua
  {
    'DimitrisDimitropoulos/yasp.nvim',
    -- lazy loading is not required, since it is handled internally
    lazy = false,
    -- if you persist on lazy loading you must call the setup function on InsertEnter
    -- event = 'InsertEnter',
    opts = {
      -- default, change to false for special completion frameworks
      -- long_desc = true,
      -- default, change to true mainly for debugging
      -- prose = false,
      -- default, the time to wait before starting a new server in milliseconds, highly suggested to keep it
      -- debounce = 750,

      -- 💀 WARNING: the following must be provided by the user
      -- the paths to the package.json files, no default given, must be provided
      paths = {
        -- for friendly-snippets installed via lazy.nvim
        vim.fn.stdpath 'data' .. '/lazy/friendly-snippets/package.json',
        -- for snippets in the users config directory
        vim.fn.expand('$MYVIMRC'):match '(.*[/\\])' .. 'snippets/path/to/package.json',
      },
      -- the accompanying descriptions for the paths, no default given, must be provided
      descs = { 'FR', 'USR' },
    },
  },
```

For other plugin managers you can setup and initiate the plugin via a call to:

```lua
require('yasp').setup {
  -- same options as above
}
```

## 🧰 Fixing Problems

In case you encounter any issues there are two integrated mechanisms to help
you tackle them. Firstly, if you have problem locating your `package.json`
running `:checkhealth yasp` can you help you. Moreover, if you have something
else you can turn on `prose`, which will give you notifications to dial down
server initialization and termination and on `checkhealth` will breakdown for
you the snippets for the active buffers filetype, in order to tackle snippet
specific problems.

## 🗺 Architecture

For anyone interested the plugin is based upon neovim's in-process language
servers. The main inspiration was
[this](https://zignar.net/2022/10/26/testing-neovim-lsp-plugins/#a-in-process-lsp-server)
article and the tests for
[this](https://github.com/mfussenegger/nvim-lsp-compl) completion plugin.
