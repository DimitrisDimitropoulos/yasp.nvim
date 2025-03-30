local M = {}

---@param config yasp.Settings
function M.setup(config)
  if config then
    require('yasp.settings').set(config)
  end

  local sn_group = vim.api.nvim_create_augroup('SnippetServer', { clear = true })
  vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
    group = sn_group,
    once = true,
    callback = function()
      require('yasp.snippet').snippet_handler(vim.bo.filetype)
      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        group = sn_group,
        callback = function()
          require('yasp.snippet').snippet_handler(vim.bo.filetype)
        end,
        desc = 'Handle LSP for buffer changes',
      })
    end,
  })
end

return M
