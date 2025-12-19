-- ===================== coc.lua =====================
-- 读取 coc 扩展列表（来自 dotfiles/coc/extensions/package.json），缺省填充常用扩展
local M = {}

function M.setup()
  local fn = vim.fn
  local path = fn.expand("~/dotfiles/coc/extensions/package.json")
  local ok, lines = pcall(fn.readfile, path)
  if ok and lines and #lines > 0 then
    local joined = table.concat(lines, "\n")
    local ok_decode, data = pcall(vim.json.decode, joined)
    if ok_decode and data and data.dependencies then
      local list = {}
      for name, _ in pairs(data.dependencies) do
        table.insert(list, name)
      end
      table.sort(list)
      vim.g.coc_global_extensions = list
      return
    end
  end

  vim.g.coc_global_extensions = {
    "coc-pyright",
    "coc-json",
    "coc-yaml",
    "coc-tsserver",
    "coc-sh",
    "coc-explorer",
    "coc-snippets",
  }
end

return M
