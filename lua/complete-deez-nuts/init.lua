local M = {}

--- Set the 'omnifunc' option for the given `buffer`.
---
--- If `buffer` is not specified, the current buffer is used instead.
---
---@param buffer? integer
function M.set_omnifunc(buffer)
  buffer = vim.F.if_nil(buffer, vim.api.nvim_get_current_buf())
  vim.bo[buffer].omnifunc = "v:lua.require'complete-deez-nuts.omnifunc'"

  local group =
    vim.api.nvim_create_augroup("complete-deez-nuts-b" .. tostring(buffer), { clear = true })

  vim.api.nvim_create_autocmd("CompleteChanged", {
    desc = "Documentation Window for LSP completion",
    buffer = buffer,
    group = group,
    callback = function()
      local event = vim.deepcopy(vim.v.event)

      if not (event and event.completed_item) then
        return
      end

      ---@type CompletionItem
      local completion = event.completed_item.user_data

      if not (completion and completion.extra_data and completion.extra_data.documentation) then
        return
      end

      local documentation = completion.extra_data.documentation

      local width = 0

      for _, line in ipairs(documentation.lines) do
        width = math.max(width, #line)
      end

      if width == 0 then
        return
      end

      local contents = documentation.lines
      local syntax = documentation.filetype
      local opts = {
        border = "single",
        height = vim.tbl_count(documentation.lines),
        width = width,
        offset_x = event.width - #event.completed_item.word + 1,
        close_events = { "CompleteChanged", "CompleteDone", "InsertLeave" },
      }

      vim.schedule(function()
        vim.lsp.util.open_floating_preview(contents, syntax, opts)
      end)
    end,
  })
end

--- Confirms the current completion, if any.
---
---@return boolean success
function M.confirm()
  if vim.fn.pumvisible() == 0 then
    return false
  end

  local completion = vim.deepcopy(vim.v.completed_item)

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-y>", true, false, true), "n", false)

  if not (completion and completion.user_data) then
    return false
  end

  if completion.user_data.extra_data and completion.user_data.extra_data.text_edits then
    local text_edits = completion.user_data.extra_data.text_edits
    local current_buf = vim.api.nvim_get_current_buf()
    local offset_encoding = completion.user_data.extra_data.offset_encoding

    vim.lsp.util.apply_text_edits(text_edits, current_buf, offset_encoding)
  end

  if completion.user_data.snippet_text then
    local snippet = completion.user_data.snippet_text
    local start_col = completion.user_data.start_col
    local end_col = start_col + #completion.user_data.insert_text

    require("complete-deez-nuts.snippets").expand(snippet, start_col, end_col)
  end

  return true
end

return M
