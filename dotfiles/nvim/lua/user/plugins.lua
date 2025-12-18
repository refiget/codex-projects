local fn = vim.fn


-- ===================== Plugin Section =====================
vim.cmd([[
call plug#begin('$HOME/.config/nvim/plugged')

" LSP / Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'fannheyward/coc-pyright'

" Treesitter / icons
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-tree/nvim-web-devicons'
		
" === Appearance ===
Plug 'theniceboy/nvim-deus'
Plug 'petertriho/nvim-scrollbar'
Plug 'HiPhish/rainbow-delimiters.nvim'
Plug 'theniceboy/eleline.vim', { 'branch': 'no-scrollbar' }
Plug 'RRethy/vim-illuminate'
Plug 'NvChad/nvim-colorizer.lua'
Plug 'kevinhwang91/nvim-hlslens'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'akinsho/bufferline.nvim', { 'tag': '*' }
Plug 'lewis6991/gitsigns.nvim'
Plug 'ryanoasis/vim-devicons'
Plug 'weirongxu/coc-explorer'


" === Telescope  ===
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'


" === Editing Helpers ===
Plug 'windwp/nvim-autopairs'
Plug 'echasnovski/mini.surround'
Plug 'junegunn/vim-after-object'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'Vimjas/vim-python-pep8-indent'

" === Markdown Preview (browser) ===
" build step ensures the web app is ready; only for markdown buffers
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install', 'for': 'markdown' }

" === LuaSnip ===
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'

call plug#end()
]])

-- 自动检查关键插件是否缺失（类似 PlugInstall），缺失时自动运行 PlugInstall --sync
local function ensure_core_plugins(after_install)
  local plug_home = fn.expand("$HOME/.config/nvim/plugged")
  local required = { "coc.nvim", "coc-pyright", "telescope.nvim", "plenary.nvim" }
  local missing = {}
  for _, name in ipairs(required) do
    if fn.empty(fn.glob(plug_home .. "/" .. name)) == 1 then
      table.insert(missing, name)
    end
  end
  if #missing > 0 then
    vim.schedule(function()
      vim.notify(
        "检测到缺少插件: " .. table.concat(missing, ", ") .. "，将自动执行 :PlugInstall --sync",
        vim.log.levels.WARN,
        { title = "Plugin install" }
      )
      vim.cmd("silent! PlugInstall --sync")
      if type(after_install) == "function" then
        after_install()
      end
    end)
    return
  end
  if type(after_install) == "function" then
    after_install()
  end
end

-- CoC 依赖检查：Node、npm/pnpm/yarn、python3 host
local function check_coc_deps()
  local warns = {}

  local function has_exec(bin)
    return fn.executable(bin) == 1
  end

  if not has_exec("node") then
    table.insert(warns, "未检测到 node，请安装 nodejs（Arch: pacman -S nodejs npm；macOS: brew install node）")
  else
    local ok, out = pcall(fn.systemlist, { "node", "-v" })
    if ok and out and out[1] then
      local major = tonumber((out[1]:match("v(%d+)") or "0"))
      if major < 14 then
        table.insert(warns, "Node 版本过低(" .. out[1] .. ")，建议 >=16 以保证 coc 稳定")
      end
    end
  end

  if not (has_exec("npm") or has_exec("pnpm") or has_exec("yarn")) then
    table.insert(warns, "未检测到 npm/pnpm/yarn，无法安装/更新 coc 扩展（Arch: pacman -S npm；macOS: brew install node）")
  end

  local host = vim.g.python3_host_prog or "python3"
  if fn.executable(host) ~= 1 then
    table.insert(warns, "未检测到 python3 host (" .. host .. ")，请安装对应解释器（Arch: pacman -S python；macOS: brew install python）")
  end

  if #warns > 0 then
    vim.schedule(function()
      vim.notify(table.concat(warns, "\n"), vim.log.levels.WARN, { title = "CoC 依赖检查" })
    end)
  end
end

-- 自动安装缺失的 coc 扩展（在 coc.nvim 可用时执行）
local function ensure_coc_extensions()
  if vim.g.__coc_extensions_installing then
    return
  end
  local exts = vim.g.coc_global_extensions
  if not exts or #exts == 0 then
    return
  end
  -- Coc 官方扩展根目录
  local ok_root, ext_root = pcall(function()
    return fn["coc#util#extension_root"]()
  end)
  local ext_home = (ok_root and ext_root and ext_root ~= "") and (ext_root .. "/node_modules")
    or (fn.stdpath("data") .. "/coc/extensions/node_modules")
  local missing = {}
  for _, name in ipairs(exts) do
    local path = ext_home .. "/" .. name
    -- 认为已安装需满足：目录存在且 package.json 存在
    local exists = fn.isdirectory(path) == 1 and fn.empty(fn.glob(path .. "/package.json")) == 0
    if not exists then
      table.insert(missing, name)
    end
  end
  if #missing == 0 then
    return
  end
  if fn.executable("node") == 0 then
    vim.schedule(function()
      vim.notify("缺少 node，无法安装 coc 扩展: " .. table.concat(missing, ", "), vim.log.levels.WARN, { title = "Coc extensions" })
    end)
    return
  end
  -- 延迟一点，确保 coc.nvim 已加载；在新 tab 中执行，避免卡主当前窗口
  vim.g.__coc_extensions_installing = true
  vim.defer_fn(function()
    local list = table.concat(missing, " ")
    vim.notify("后台安装 coc 扩展: " .. list, vim.log.levels.INFO, { title = "Coc extensions" })
    vim.cmd("tabnew")
    -- 异步安装，网络慢时不会被提前关闭
    vim.cmd("silent! CocInstall " .. list)
    -- 返回主 tab，安装日志留在新 tab
    vim.cmd("tabprevious")
    -- 约 10s 后清理标记，允许后续重试
    vim.defer_fn(function()
      vim.g.__coc_extensions_installing = false
    end, 10000)
  end, 500)
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    ensure_core_plugins(function()
      check_coc_deps()
      ensure_coc_extensions()
    end)
  end,
})

-- ===================== Telescope =====================
pcall(function()
  local telescope = require("telescope")
  telescope.setup({
    defaults = {
      -- 轻量一点的按键，不和你现有习惯冲突
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
        n = {
          ["j"] = "move_selection_next",
          ["k"] = "move_selection_previous",
        },
      },
    },
  })
end)
-- ===================== UI / Appearance =====================

vim.opt.termguicolors = true
vim.cmd("silent! colorscheme deus")

vim.api.nvim_set_hl(0, "NonText", { fg = "grey10" })
vim.g.rainbow_active = 1
vim.g.Illuminate_delay = 750
vim.api.nvim_set_hl(0, "illuminatedWord", { undercurl = true })

vim.g.lightline = {
  active = {
    left = {
      { 'mode', 'paste' },
      { 'readonly', 'filename', 'modified' },
    },
  },
}

-- ===================== Plugin Configurations =====================

pcall(function()
  require("scrollbar").setup()
  require("scrollbar.handlers.search").setup()
end)

pcall(function()
  require("colorizer").setup({
    filetypes = { "*" },
    user_default_options = {
      RGB = true,
      RRGGBB = true,
      names = true,
      AARRGGBB = true,
      mode = "virtualtext",
      virtualtext = "■",
    },
  })
end)

pcall(function()
  require("nvim-web-devicons").setup({
    color_icons = true,
    default = true,
    override = {
      folder = { icon = "", color = "#bd93f9", name = "folder" },
      folder_open = { icon = "", color = "#bd93f9", name = "folder_open" },
      default_icon = { icon = "", color = "#bd93f9", name = "folder" },
    },
  })
  -- 让 coc-explorer 文件夹图标颜色与 Yazi Dracula Pro 一致
  local purple = "#bd93f9"
  local hl = vim.api.nvim_set_hl
  hl(0, "CocExplorerFolderIcon", { fg = purple })
  hl(0, "CocExplorerFileDirectory", { fg = purple })
  hl(0, "CocExplorerFileDirectoryHidden", { fg = purple })
  hl(0, "CocExplorerSymbolicLink", { fg = purple })
  hl(0, "CocExplorerSymbolicLinkTarget", { fg = purple })
end)

-- markdown-preview.nvim 默认浏览器行为与构建配置
vim.g.mkdp_auto_start = 0          -- 不自动打开
vim.g.mkdp_auto_close = 1          -- 关闭预览时关闭浏览器页
vim.g.mkdp_refresh_slow = 0
vim.g.mkdp_command_for_global = 0
vim.g.mkdp_open_to_the_world = 0
vim.g.mkdp_filetypes = { "markdown" }
-- macOS: 使用系统默认浏览器；如需指定，设置 mkdp_browser 或 mkdp_browserfunc
vim.g.mkdp_browser = ""            -- 空 = 默认浏览器

-- xtabline 配置：tabs/buffers 模式，不启用默认映射
-- ===================== Final tweaks =====================
vim.opt.re = 0
vim.cmd("nohlsearch")
vim.g.eleline_colorscheme = 'deus'
vim.g.eleline_powerline_fonts = 0


-- =============================
-- Safe rainbow delimiter colors
-- =============================
local soft = "#88c0a0"   -- 散光友好颜色

vim.g.rainbow_conf = {
  guifgs = {
    "#ff5555",  -- red
    "#f1fa8c",  -- yellow
    soft,       -- blue → 柔和青绿
    "#bd93f9",  -- purple
    "#50fa7b",  -- green
  },
  ctermfgs = { "Red", "Yellow", "Green", "Cyan", "Magenta" },
}

pcall(function()
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if not ok then
    ok, configs = pcall(require, "nvim-treesitter.config")
  end

  if not ok or not configs or type(configs.setup) ~= "function" then
    vim.notify("未找到 nvim-treesitter 配置模块，已跳过 treesitter 配置", vim.log.levels.WARN)
    return
  end

  configs.setup({
    ensure_installed = {
      "lua","vim","markdown","markdown_inline","python","json","bash","javascript","c"
    },
    highlight = { enable = true },
    indent = { enable = true },
  })
end)

pcall(function()
  require('gitsigns').setup({
    signs = {
      add          = { hl = 'GitSignsAdd'   , text = '▎', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'    },
      change       = { hl = 'GitSignsChange', text = '░', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
      delete       = { hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
      topdelete    = { hl = 'GitSignsDelete', text = '▔', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn' },
      changedelete = { hl = 'GitSignsChange', text = '▒', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn' },
      untracked    = { hl = 'GitSignsAdd'   , text = '┆', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'    },
    },
  })
end)
-- ========================
-- Bufferline (Beautiful Tabs)
-- ========================
pcall(function()
  require("bufferline").setup({
    options = {
      mode = "tabs",          -- 只显示真实 tab，避免 buffer 残留
      numbers = "ordinal",
      diagnostics = "coc",   -- 你用 coc.nvim，所以这里用 coc
      separator_style = "slant", -- "slant" | "padded_slant" | "thick" | "thin"
      show_close_icon = false,
      show_buffer_close_icons = false,
      color_icons = true,
      always_show_bufferline = true,
    }
  })
end)
