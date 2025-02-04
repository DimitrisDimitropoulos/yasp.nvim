local M = {}

---@param config yasp.Settings
function M.setup(config)
  if config then
    require('yasp.settings').set(config)
  end

  local cur_sett = require('yasp.settings').current

  local sn_group = vim.api.nvim_create_augroup('SnippetServer', { clear = true })
  vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
    group = sn_group,
    once = true,
    callback = function()
      require('yasp.snippet').snippet_handler(cur_sett.paths, vim.bo.filetype, cur_sett.descs)
      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        group = sn_group,
        callback = function()
          require('yasp.snippet').snippet_handler(cur_sett.paths, vim.bo.filetype, cur_sett.descs)
        end,
        desc = 'Handle LSP for buffer changes',
      })
    end,
  })
end

return M
