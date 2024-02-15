---@see :help 'omnifunc'
return function()
  local util = require("complete-deez-nuts.util")

  local start_col, cursor_word = util.findstart()
  local completions = {}

  ---@param completion CompletionItem
  local add_completion = function(completion)
    if not util.matches(completion.insert_text, cursor_word) then
      return
    end

    table.insert(completions, {
      word = completion.insert_text,
      abbr = completion.display_text,
      menu = completion.extra_text,
      kind = completion.kind,
      icase = 1,
      dup = 1,
      user_data = completion,
    })

    table.sort(completions, function(a, b)
      return util.cmp(a.user_data, b.user_data)
    end)

    vim.fn.complete(start_col + 1, completions)
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()
  local method = "textDocument/completion"
  local clients = vim.lsp.get_clients({
    bufnr = current_buf,
    method = method,
  })

  if vim.tbl_isempty(clients) then
    vim.notify("No LSP clients capable of providing completion found.", vim.log.levels.WARN)
    return -3
  end

  for _, client in ipairs(clients) do
    local params = vim.lsp.util.make_position_params(current_win, client.offset_encoding)

    client.request(method, params, function(err, result)
      if err then
        vim.notify(
          "Failed to request completions from `" .. client.name .. "`: " .. vim.inspect(err),
          vim.log.levels.ERROR
        )
        return
      end

      if not result then
        return
      end

      for _, item in ipairs(result.items) do
        client.request("completionItem/resolve", item, function(err, result)
          if (not err) and result then
            item = vim.tbl_deep_extend("force", item, result)
          end

          add_completion(util.extract_info(item, client.offset_encoding, start_col, cursor_word))
        end, current_buf)
      end
    end, current_buf)
  end

  return -2
end
