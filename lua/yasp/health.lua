local M = {}

---@mod yasp.health Health check module for yasp

---@brief [[
---Health checks at the moment are rudimentary. They check primarily the
---validity of the package.jsons. As an added bonus, if prose is enabled there
---is some basic checking for the snippets that are assigned to the opened
---buffers, mainly for debugging purposes.
---@brief ]]

---@param paths string[] A table of paths to check
local function validate_package_json(paths)
  for _, path in ipairs(paths) do
    local stat = vim.uv.fs_stat(path)
    if not stat then
      vim.health.error('File not found: ' .. path)
    elseif stat.type ~= 'file' then
      vim.health.error('Not a file: ' .. path)
    else
      local ok, data = pcall(function()
        local content = require('yasp.snippet').read_file(path)
        return vim.json.decode(content)
      end)
      if not ok or type(data) ~= 'table' then
        vim.health.error('Invalid package.json: ' .. path)
      else
        vim.health.ok('Valid package.json: ' .. path)
      end
    end
  end
end

---@return string[] filetypes A list of filetypes
local function get_bufs()
  -- Get a list of all buffer numbers
  local buffers = vim.api.nvim_list_bufs()
  -- Table to store filetypes
  local filetypes = {}
  -- Iterate through each buffer
  for _, buf in ipairs(buffers) do
    -- Check if the buffer is loaded and listed
    if vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
      -- Get the filetype of the buffer
      local ft = vim.api.nvim_get_option_value('filetype', { buf = buf })
      -- Add the filetype to the table if it's not already present
      if ft ~= '' and ft ~= 'checkhealth' and not vim.tbl_contains(filetypes, ft) then
        table.insert(filetypes, ft)
      end
    end
  end
  return filetypes
end

---@param fts string[] A table of filetypes
---@param paths string[] A table of paths to check
---@param descs string[] A table of descriptions
local function print_active_snippets(fts, paths, descs)
  for _, ft in ipairs(fts) do
    local snippets = require('yasp.snippet').concat_all(paths, ft, descs)
    vim.health.start('Snippets for filetype: ' .. ft .. '\n')
    for _, item in ipairs(snippets.items) do
      vim.health.info(vim.inspect(item))
    end
  end
end

---@private
M.check = function()
  vim.health.start 'yasp health check'
  if vim.version().minor >= 10 then
    vim.health.ok 'Neovim version is supported'
  else
    vim.health.error 'Neovim version is not supported, please upgrade to 0.10.x or later'
  end
  validate_package_json(require('yasp.settings').current.paths)
  if require('yasp.settings').current.prose then
    print_active_snippets(get_bufs(), require('yasp.settings').current.paths, require('yasp.settings').current.descs)
  end
end

return M
