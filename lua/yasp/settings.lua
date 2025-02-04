local M = {}

---@mod yasp.Introduction Introduction to yasp
---@brief [[
---yasp is a simple way to manage your snippets in a completion engine agnostic
---way. Thus it enables you to use jump around completion frameworks with ease,
---even native autocompletion for the nightly users. The plugin is designed to
---manage multiple snippet sources such as friendly-snippets and use defined.
---It shall be noted that yasp manages only LSP/vscode/json snippets, therefore
---fancy lua snippets are not supported. At last, you must configure some basic
---functionality for yourself, mainly the package.json paths
---
---The package.json files are the indexes which direct yasp to pick the right
---snippets.json for the according filetype. For examples you can refer to these:
---
---  - https://github.com/rafamadriz/friendly-snippets/blob/main/package.json
---  - https://github.com/DimitrisDimitropoulos/nvim/blob/main/snippets/json_snippets/package.json
---
---Generally, if have ever used json snippets with a package.json for plugins
---like luasnip it is very likely that it will continue to work.
---@brief ]]
---@see yasp.settings

---@toc yasp.contents

---@mod yasp.settings Settings for yasp

---Setting available for yasp
---@class yasp.Settings
---@field paths string[] Paths of the package.json files to check
---@field descs string[] List of descriptions to describe each package.json file
---@field prose boolean If true, messages will be made describing the usage of the server and checkhealth will return the snippets for all active buffer filetypes

---@brief [[
---The default settings for yasp
--->lua
--- require('yasp').setup({
---  paths = {},
---  descs = {},
---  prose = false,
--- })
---<
---
---Therefore paths must be explicitly set to the package.json files to check
---for the appropriate files. It is recommended to set the paths leveraging
---vim's vim.fn and not absolute paths. For example, in order to use
---friendly-snippets installed by lazy.nvim, you can use:
--->lua
--- vim.fn.stdpath 'data' .. '/lazy/friendly-snippets/package.json',
---<
---Moreover, to use snippets from the user's nvim configuration, you can use,
---something along the lines of:
--->lua
--- vim.fn.expand('$MYVIMRC'):match '(.*[/\\])' .. 'path/to/package.json',
---<
---@brief ]]

---@type yasp.Settings
local _default = {
  paths = {},
  descs = {},
  prose = false,
}

---@private
---@type yasp.Settings
M.current = _default

---@private
---@param opts yasp.Settings
function M.set(opts)
  M.current = vim.tbl_deep_extend('force', vim.deepcopy(M.current), opts)
end

return M
