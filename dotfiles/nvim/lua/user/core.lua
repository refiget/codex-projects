-- ===================== core.lua =====================
local fn = vim.fn
local opt = vim.opt
local g = vim.g

-- -------------------- Environment --------------------
vim.env.PYTHONWARNINGS = "ignore::SyntaxWarning"
if fn.isdirectory(fn.getcwd()) == 0 then vim.cmd("cd ~") end

-- -------------------- Python Provider --------------------
local function detect_python_host()
  local candidates = {
    fn.expand("~/venvs/nvim/bin/python3"),            -- user venv (no dot)
    fn.expand("~/.venvs/nvim/bin/python3"),           -- user venv (with dot)
    "/usr/local/opt/python@3/bin/python3",            -- macOS Homebrew (versioned)
    "/opt/homebrew/bin/python3",                      -- macOS Homebrew (Apple Silicon)
    "/usr/local/bin/python3",                         -- macOS/Linux alt
    "/usr/bin/python3",                               -- system default
  }
  for _, path in ipairs(candidates) do
    if fn.executable(path) == 1 then
      return path
    end
  end
  return "python3"
end

g.python3_host_prog = detect_python_host()

-- -------------------- Editor Behavior --------------------
opt.undolevels = 10000
opt.breakindent = true
opt.linebreak = true
opt.undoreload = 10000
opt.swapfile = false
opt.laststatus = 2
opt.exrc = true
opt.secure = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.expandtab = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.autoindent = true
opt.list = true
opt.listchars = { tab = "| ", trail = "▫" }
opt.scrolloff = 4
opt.ttimeoutlen = 0
opt.timeout = false
opt.viewoptions = { "cursor", "folds", "slash", "unix" }
opt.wrap = true
opt.foldmethod = "indent"
opt.foldlevel = 99
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.completeopt = { "menuone", "noselect" }
opt.updatetime = 100
opt.virtualedit = "block"
opt.inccommand = "split"
opt.showmode = false
opt.lazyredraw = true
opt.visualbell = true
opt.colorcolumn = "100"

opt.backupdir = fn.expand("$HOME/.config/nvim/tmp/backup,.")
opt.directory = fn.expand("$HOME/.config/nvim/tmp/backup,.")
opt.undodir = fn.expand("$HOME/.config/nvim/tmp/undo,.")

if fn.has("persistent_undo") == 1 then opt.undofile = true end

-- -------------------- Autocommands --------------------
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  command = [[if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  command = "startinsert",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.md",
  command = "setlocal spell",
})
