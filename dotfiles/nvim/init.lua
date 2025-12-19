-- ===================== init.lua =====================
-- === Load Core Modules ===
require("user.core")
require("user.plugins")

-- === Coc Extensions (auto-install) ===
local fn = vim.fn
local function load_coc_extensions()
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
  -- fallback: 常用扩展
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
load_coc_extensions()

require("user.keymaps")
-- === LuaSnip Setup ===
-- Load LuaSnip safely
local ok, ls = pcall(require, "luasnip")
if not ok then
  print("LuaSnip not found — did you run :PlugInstall?")
  return
end

-- LuaSnip global configuration
ls.config.set_config({
  history = true,                         -- keep last snippet for jumping
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})


-- === Load Snippets ===
-- Load your custom Lua snippets (in dotfiles)
require("luasnip.loaders.from_lua").lazy_load({ paths = "~/dotfiles/nvim/lua/snippets" })
-- Load friendly-snippets (community snippets)
require("luasnip.loaders.from_vscode").lazy_load()

-- === Keymaps for Snippet / PUM Expansion ===
vim.keymap.set("i", "<Tab>", function()
  if vim.fn["coc#pum#visible"]() == 1 then
    return vim.fn["coc#pum#next"](1)
  end
  if vim.fn["coc#expandableOrJumpable"]() == 1 then
    return vim.fn["coc#rpc#request"]("doKeymap", { "snippets-expand-jump", "" })
  end
  return vim.fn["coc#refresh"]()
end, { silent = true, noremap = true, expr = true })

vim.keymap.set("i", "<S-Tab>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]],
  { silent = true, noremap = true, expr = true })

vim.keymap.set("i", "<C-Space>", "coc#refresh()", { silent = true, noremap = true, expr = true })




-- 默认使用系统剪贴板提供者（pbcopy/xclip 等），不覆写 clipboard 提供者，
-- y 走默认寄存器，Y 由按键映射复制到 + 寄存器。
vim.opt.clipboard = ""
-- 统一剪贴板：tmux -> 系统工具 -> OSC52（远程也能回传本地剪贴板）
do
  local copy = vim.fn.expand("~/.config/tmux/scripts/copy_to_clipboard.sh")
  local paste = vim.fn.expand("~/.config/tmux/scripts/paste_from_clipboard.sh")
  if vim.fn.executable(copy) == 1 and vim.fn.executable(paste) == 1 then
    vim.g.clipboard = {
      name = "tmux-osc52",
      copy = { ["+"] = copy, ["*"] = copy },
      paste = { ["+"] = paste, ["*"] = paste },
      cache_enabled = 0,
    }
  end
end
