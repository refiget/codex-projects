-- ===================== options.lua =====================
local fn = vim.fn
local opt = vim.opt

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
opt.re = 0

opt.backupdir = fn.expand("$HOME/.config/nvim/tmp/backup,.")
opt.directory = fn.expand("$HOME/.config/nvim/tmp/backup,.")
opt.undodir = fn.expand("$HOME/.config/nvim/tmp/undo,.")

if fn.has("persistent_undo") == 1 then
  opt.undofile = true
end

vim.cmd("nohlsearch")
