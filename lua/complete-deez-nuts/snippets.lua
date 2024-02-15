local M = {}

--- Expands the given `snippet` over the range of `start_col`..=`end_col`.
---
---@param snippet string
---@param start_col integer
---@param end_col integer
---
---@see :help vim.snippet.expand()
function M.expand(snippet, start_col, end_col)
  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(current_win)
  local row = cursor[1] - 1

  vim.api.nvim_buf_set_text(current_buf, row, start_col, row, end_col, {})
  vim.snippet.expand(snippet)
end

return M
