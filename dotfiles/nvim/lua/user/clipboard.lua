-- ===================== clipboard.lua =====================
-- 默认使用系统剪贴板提供者（pbcopy/xclip 等），不覆写 clipboard 提供者，
-- y 走默认寄存器，Y 由按键映射复制到 + 寄存器。
vim.opt.clipboard = ""

local function first_exec(paths)
  for _, p in ipairs(paths) do
    local expanded = vim.fn.expand(p)
    if vim.fn.executable(expanded) == 1 then
      return expanded
    end
  end
end

local copy = first_exec({ "~/.config/tmux/scripts/copy_to_clipboard.sh", "~/dotfiles/tmux/scripts/copy_to_clipboard.sh" })
local paste = first_exec({ "~/.config/tmux/scripts/paste_from_clipboard.sh", "~/dotfiles/tmux/scripts/paste_from_clipboard.sh" })

if copy and paste then
  vim.g.clipboard = {
    name = "tmux-osc52",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end
