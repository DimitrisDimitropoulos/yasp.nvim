local M = {}

---@mod yasp.snippet Utility functions for handling snippets

---@brief [[
---This part is mainly for user who are eager to tinker with in-process LSPs
---and mess with own sources etc. Please not that breaking changes will happen
---to this part and may not be well communicated to end users.
---Proceed with caution.
---@brief ]]

---A table containing completion results formatted for LSP
---@alias yasp.CompTable table

---@private
---Read the content of a file as a string.
---the read is done with the permissions rrr (read only)
---@param path string Path to the file
---@return string buffer Contents of file as a string
---@usage `local buffer = require('yasp.snippet').read_file('path/to/file')`
function M.read_file(path)
  -- permissions: rrr
  --
  local fd = assert(vim.uv.fs_open(path, 'r', tonumber('0444', 8)))
  local stat = assert(vim.uv.fs_fstat(fd))
  -- read from offset 0.
  local buf = assert(vim.uv.fs_read(fd, stat.size, 0))
  vim.uv.fs_close(fd)
  return buf
end

---Parse the pkg.json file and return a list of snippet paths
---@param pkg_path string Path to the package.json file
---@param lang string The language to filter the snippets by
---@return string[] file_paths List of absolute paths to the snippet files
local function parse_pkg(pkg_path, lang)
  local pkg = M.read_file(pkg_path)
  local data = vim.json.decode(pkg)
  local base_path = vim.fn.fnamemodify(pkg_path, ':h')
  local file_paths = {}
  for _, snippet in ipairs(data.contributes.snippets) do
    local languages = snippet.language
    -- Check if it's a list of languages or a single language
    if type(languages) == 'string' then
      languages = { languages }
    end
    -- If a language is provided, check for a match
    if not lang or vim.tbl_contains(languages, lang) then
      -- Prepend the base path to the relative snippet path
      local abs_path = vim.fn.fnamemodify(base_path .. '/' .. snippet.path, ':p')
      table.insert(file_paths, abs_path)
    end
  end
  return file_paths
end

---Process only one JSON encoded string
---@param snips string JSON encoded string containing snippets
---@param desc string Description for the snippets (optional)
---@return yasp.CompTable completion_results A table containing completion results formatted for LSP
local function process_snippets(snips, desc)
  local snippets_table = {}
  local snippet_descs = {}
  local completion_results = {
    isIncomplete = false,
    items = {},
  }
  -- Decode the JSON input
  for _, v in pairs(vim.json.decode(snips)) do
    local prefixes = type(v.prefix) == 'table' and v.prefix or { v.prefix }
    -- Handle v.body as a table or string
    local body
    if type(v.body) == 'table' then
      -- Concatenate the table elements into a single string, separated by newlines
      body = table.concat(v.body, '\n')
    else
      -- If it's already a string, use it directly
      body = v.body
    end
    -- Add each prefix-body pair to the table
    for _, prefix in ipairs(prefixes) do
      snippets_table[prefix] = body
      snippet_descs[prefix] = v.description
    end
  end
  -- Transform the snippets_table into completion_results
  for label, insertText in pairs(snippets_table) do
    table.insert(completion_results.items, {
      detail = tostring(desc) .. '|' .. tostring(snippet_descs[label] or 'User Snippet'),
      label = label,
      kind = vim.lsp.protocol.CompletionItemKind['Snippet'],
      documentation = {
        value = insertText,
        kind = vim.lsp.protocol.MarkupKind.Markdown,
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = insertText,
      -- fix for blink.cmp
      sortText = tostring(1.02), -- Ensure a low score by setting a high sortText value, not sure
    })
  end
  return completion_results
end

---Concatenates all the snippets from all the given paths into a single source.
---The simplest way to create a completion table source.
---@param paths string[] List of paths to the pkg.json files
---@param ft string The filetype
---@param descs string[] A table of descriptions for each path
---@return yasp.CompTable all_snippets A table containing completion results formatted for LSP
---@see yasp.CompTable
function M.concat_all(paths, ft, descs)
  local all_snippets = { isIncomplete = false, items = {} }
  for i, pkg_path in ipairs(paths) do
    local snippet_paths = parse_pkg(pkg_path, ft)
    for _, snips_path in ipairs(snippet_paths) do
      local snips = M.read_file(snips_path)
      local desc = descs and descs[i] or 'SN'
      local lsp_snip = process_snippets(snips, desc)
      if lsp_snip and lsp_snip.items then
        for _, snippet_item in ipairs(lsp_snip.items) do
          table.insert(all_snippets.items, snippet_item)
        end
      end
    end
  end
  return all_snippets
end

---@param completion_source yasp.CompTable The completion result to be returned by the server
---@return function server A function that creates a new server instance
local function new_server(completion_source)
  local function server(dispatchers)
    local closing = false
    local srv = {}
    function srv.request(method, _params, handler)
      if method == 'initialize' then
        handler(nil, {
          capabilities = {
            completionProvider = {
              triggerCharacters = { '{', '(', '[', ' ', '.', ':', ',' },
            },
          },
        })
      elseif method == 'textDocument/completion' then
        handler(nil, completion_source)
      elseif method == 'shutdown' then
        handler(nil, nil)
      end
    end
    function srv.notify(method, _)
      if method == 'exit' then
        dispatchers.on_exit(0, 15)
      end
    end
    function srv.is_closing()
      return closing
    end
    function srv.terminate()
      closing = true
    end
    return srv
  end
  return server
end

---Start a mock LSP server with the given completion source. The id of the
---client may not be that useful
---@param completion_source yasp.CompTable The completion source to be used by the mock
---@return integer client_id The ID of the client that was started
---@see yasp.CompTable
function M.start_mock_lsp(completion_source)
  local server = new_server(completion_source)
  local dispatchers = {
    on_exit = function(code, signal)
      vim.notify('Server exited with code ' .. code .. ' and signal ' .. signal, vim.log.levels.ERROR)
    end,
  }
  local client_id = vim.lsp.start({
    name = 'sn_ls',
    cmd = server,
    root_dir = vim.uv.cwd(), -- not needed actually
    on_init = function(_client)
      -- vim.notify('Snippet LSP server initialized', vim.log.levels.INFO)
    end,
    on_exit = function(_code, _signal)
      --   vim.notify('Snippet LSP server exited with code ' .. code .. ' and signal ' .. signal, vim.log.levels.ERROR)
    end,
  }, dispatchers)
  return client_id ---@type integer
end

---Create a callback to handle the destruction of the previous LSP client and
---the creation of a new one. Basically a wrapper for usage with autocmds
---@param paths string[] List of paths to the JSON snippet files
---@param ft string Filetype of the current buffer
---@param descs string[] List of descriptions for the snippet sources
function M.snippet_handler(paths, ft, descs)
  -- Stop the previous LSP client if it exists
  local client = vim.lsp.get_clients({ name = 'sn_ls' })[1]
  if client then
    vim.lsp.stop_client(client.id)
    if require('yasp.settings').current.prose then
      vim.notify('Stopped previous sn_ls client with ' .. client.id, vim.log.levels.INFO)
    end
  end
  -- Make sure the new server is started after the previous one is stopped
  vim.defer_fn(function()
    if ft ~= '' then -- do not run on empty filetype causes weird behavior
      local all_snippets = M.concat_all(paths, ft, descs)
      local client_id = M.start_mock_lsp(all_snippets)
      if require('yasp.settings').current.prose then
        vim.notify('Started new sn_ls client with ' .. client_id .. ' for ' .. ft, vim.log.levels.INFO)
      end
    end
  end, 750)
end

return M
