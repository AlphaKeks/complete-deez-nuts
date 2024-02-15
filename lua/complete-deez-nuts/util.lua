local M = {}

--- Finds the start column for a completion.
---
---@return integer start_col, string cursor_word
---
---@see :help complete-functions
function M.findstart()
  local window_id = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(window_id)
  local line = vim.api.nvim_get_current_line()
  local relevant_part = line:sub(1, cursor[2])
  local start_col = vim.fn.match(relevant_part, "\\k*$")
  local end_col = vim.fn.col("$") - 1
  local cursor_word = relevant_part:sub(start_col + 1)
  local char_after_cursor = line:sub(cursor[2] + 1, cursor[2] + 1)

  if vim.fn.match(char_after_cursor, "\\k") ~= -1 and cursor[2] ~= end_col then
    cursor_word = vim.fn.expand("<cword>")
  end

  return start_col, cursor_word
end

--- Determines whether a given `word` match another word.
---
---@param word string
---@param other
---
---@return boolean matches
function M.matches(word, other)
  if #other == 0 then
    return true
  end

  return word:lower():match(other:lower())
end

--- Compares two words and orders them.
---
---@param a string
---@param b string
---
---@return boolean a_has_priority
function M.cmp(a, b)
  local input = a.input_text:lower()
  local a_text = a.insert_text:lower()
  local b_text = b.insert_text:lower()
  local a_matches = input ~= "" and a_text:match(input)
  local b_matches = input ~= "" and b_text:match(input)

  if a_matches and not b_matches then
    return true
  end

  if not a_matches and b_matches then
    return false
  end

  if a.snippet_text and not b.snippet_text then
    return true
  end

  if not a.snippet_text and b.snippet_text then
    return false
  end

  if #a_text ~= #b_text then
    return #a_text < #b_text
  end

  -- ¯\_(ツ)_/¯
  return a_text < b_text
end

--- Extracts information from an LSP completion item.
---
---@param item lsp.CompletionItem
---@param offset_encoding string
---@param start_col integer
---@param word string
---
---@return CompletionItem | nil completion
function M.extract_info(item, offset_encoding, start_col, word)
  local insert_text = nil
  local display_text = nil
  local extra_text = nil
  local snippet_text = nil

  if item.label then
    insert_text = item.label
    display_text = item.label
  end

  ---@param text string
  local search_snippet = function(text)
    local has_snippet_node = vim.iter({ "$0", "${0:", "$1", "${1:" }):any(function(pattern)
      return text:find(pattern, 1, true)
    end)

    if has_snippet_node then
      snippet_text = text
    else
      insert_text = text
      display_text = display_text or text
    end
  end

  if item.textEdit and item.textEdit.newText then
    search_snippet(item.textEdit.newText)
  end

  if item.insertText then
    search_snippet(item.insertText)
  end

  if item.filterText then
    insert_text = item.filterText
    display_text = display_text or item.filterText
  end

  if not insert_text then
    return nil
  end

  if not display_text then
    display_text = insert_text
  end

  ---@type CompletionItem
  local completion = {
    start_col = start_col,
    input_text = word,
    insert_text = insert_text,
    display_text = display_text,
    extra_text = extra_text,
    snippet_text = snippet_text,
    kind = vim.lsp.protocol.CompletionItemKind[item.kind],
    extra_data = {
      offset_encoding = offset_encoding,
      text_edits = item.additionalTextEdits,
    },
  }

  if type(item.documentation) == "string" then
    completion.extra_data.documentation = {
      filetype = "markdown",
      lines = vim.split(item.documentation, "\n"),
    }
  elseif item.documentation then
    completion.extra_data.documentation = {
      filetype = item.documentation.kind,
      lines = vim.split(item.documentation.value, "\n"),
    }
  end

  return completion
end

return M
