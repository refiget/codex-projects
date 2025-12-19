-- ===================== snippets.lua =====================
-- LuaSnip 初始化与按键
local ok, ls = pcall(require, "luasnip")
if not ok then
  print("LuaSnip not found — did you run :Lazy sync?")
  return
end

ls.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})

require("luasnip.loaders.from_lua").lazy_load({ paths = "~/dotfiles/nvim/lua/snippets" })
require("luasnip.loaders.from_vscode").lazy_load()

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
