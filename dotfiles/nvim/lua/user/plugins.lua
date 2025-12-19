local fn = vim.fn
local lazypath = fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

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
  if fn.exists("*coc#util#extension_root") == 0 then
    return
  end
  local ok_root, ext_root = pcall(function()
    return fn["coc#util#extension_root"]()
  end)
  local ext_home = (ok_root and ext_root and ext_root ~= "") and (ext_root .. "/node_modules")
    or (fn.stdpath("data") .. "/coc/extensions/node_modules")
  local missing = {}
  for _, name in ipairs(exts) do
    local path = ext_home .. "/" .. name
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
  vim.g.__coc_extensions_installing = true
  vim.defer_fn(function()
    local list = table.concat(missing, " ")
    vim.notify("后台安装 coc 扩展: " .. list, vim.log.levels.INFO, { title = "Coc extensions" })
    vim.cmd("tabnew")
    vim.cmd("silent! CocInstall " .. list)
    vim.cmd("tabprevious")
    vim.defer_fn(function()
      vim.g.__coc_extensions_installing = false
    end, 10000)
  end, 500)
end

local function trigger_coc_extension_install()
  if vim.fn.exists("*coc#util#extension_root") == 0 then
    return
  end
  ensure_coc_extensions()
end

local plugins = {
  -- LSP / Completion
  { "neoclide/coc.nvim", branch = "release", lazy = false },
  { "fannheyward/coc-pyright", lazy = false },

  -- Treesitter / icons
  { "nvim-treesitter/nvim-treesitter", lazy = false },

  -- Appearance
  {
    "theniceboy/nvim-deus",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.termguicolors = true
      vim.cmd("silent! colorscheme deus")
      vim.api.nvim_set_hl(0, "NonText", { fg = "grey10" })
      vim.g.rainbow_active = 1
      vim.g.Illuminate_delay = 750
      vim.api.nvim_set_hl(0, "illuminatedWord", { undercurl = true })
      vim.g.lightline = {
        active = {
          left = {
            { "mode", "paste" },
            { "readonly", "filename", "modified" },
          },
        },
      }
      vim.g.eleline_colorscheme = "deus"
      vim.g.eleline_powerline_fonts = 0
    end,
  },
  {
    "petertriho/nvim-scrollbar",
    lazy = false,
    config = function()
      local ok, scrollbar = pcall(require, "scrollbar")
      if not ok then
        return
      end
      scrollbar.setup()
      local ok_search, search = pcall(require, "scrollbar.handlers.search")
      if ok_search then
        search.setup()
      end
    end,
  },
  { "HiPhish/rainbow-delimiters.nvim", lazy = false },
  { "theniceboy/eleline.vim", branch = "no-scrollbar", lazy = false },
  { "RRethy/vim-illuminate", lazy = false },
  {
    "NvChad/nvim-colorizer.lua",
    lazy = false,
    config = function()
      local ok, colorizer = pcall(require, "colorizer")
      if not ok then
        return
      end
      colorizer.setup({
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
    end,
  },
  { "kevinhwang91/nvim-hlslens", lazy = false },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    lazy = false,
    config = function()
      local ok, bufferline = pcall(require, "bufferline")
      if not ok then
        return
      end
      bufferline.setup({
        options = {
          mode = "tabs",
          numbers = "ordinal",
          diagnostics = "coc",
          separator_style = "slant",
          show_close_icon = false,
          show_buffer_close_icons = false,
          color_icons = true,
          always_show_bufferline = true,
        },
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      local ok, gitsigns = pcall(require, "gitsigns")
      if not ok then
        return
      end
      gitsigns.setup({
        signs = {
          add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
          change = { hl = "GitSignsChange", text = "░", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
          delete = { hl = "GitSignsDelete", text = "_", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
          topdelete = { hl = "GitSignsDelete", text = "▔", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
          changedelete = { hl = "GitSignsChange", text = "▒", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
          untracked = { hl = "GitSignsAdd", text = "┆", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
        },
      })
    end,
  },
  { "ryanoasis/vim-devicons", lazy = false },
  { "weirongxu/coc-explorer", lazy = false },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      local ok, devicons = pcall(require, "nvim-web-devicons")
      if not ok then
        return
      end
      devicons.setup({
        color_icons = true,
        default = true,
        override = {
          folder = { icon = "", color = "#bd93f9", name = "folder" },
          folder_open = { icon = "", color = "#bd93f9", name = "folder_open" },
          default_icon = { icon = "", color = "#bd93f9", name = "folder" },
        },
      })
      local purple = "#bd93f9"
      local hl = vim.api.nvim_set_hl
      hl(0, "CocExplorerFolderIcon", { fg = purple })
      hl(0, "CocExplorerFileDirectory", { fg = purple })
      hl(0, "CocExplorerFileDirectoryHidden", { fg = purple })
      hl(0, "CocExplorerSymbolicLink", { fg = purple })
      hl(0, "CocExplorerSymbolicLinkTarget", { fg = purple })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local ok, telescope = pcall(require, "telescope")
      if not ok then
        return
      end
      telescope.setup({
        defaults = {
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
    end,
  },
  { "nvim-lua/plenary.nvim", lazy = false },

  -- Editing Helpers
  { "windwp/nvim-autopairs", lazy = false },
  { "echasnovski/mini.surround", lazy = false },
  { "junegunn/vim-after-object", lazy = false },
  { "lukas-reineke/indent-blankline.nvim", lazy = false },
  { "Vimjas/vim-python-pep8-indent", lazy = false },

  -- Markdown Preview (browser)
  {
    "iamcco/markdown-preview.nvim",
    lazy = false,
    build = "cd app && npm install",
    ft = { "markdown" },
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_browser = ""
    end,
  },

  -- LuaSnip
  { "L3MON4D3/LuaSnip", lazy = false },
  { "rafamadriz/friendly-snippets", lazy = false },
}

require("lazy").setup(plugins, {
  defaults = { lazy = false },
  ui = { border = "rounded" },
  install = {
    missing = true,  -- 启动时自动安装缺失插件
  },
})

local soft = "#88c0a0"
vim.g.rainbow_conf = {
  guifgs = {
    "#ff5555",
    "#f1fa8c",
    soft,
    "#bd93f9",
    "#50fa7b",
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
      "lua", "vim", "markdown", "markdown_inline", "python", "json", "bash", "javascript", "c",
    },
    highlight = { enable = true },
    indent = { enable = true },
  })
end)

local aug = vim.api.nvim_create_augroup("UserCocInstall", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = aug,
  pattern = "LazyDone",
  callback = function()
    check_coc_deps()
    vim.defer_fn(trigger_coc_extension_install, 500)
  end,
})
vim.api.nvim_create_autocmd("User", {
  group = aug,
  pattern = "CocNvimInit",
  callback = function()
    vim.defer_fn(trigger_coc_extension_install, 200)
  end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = aug,
  callback = function()
    vim.defer_fn(trigger_coc_extension_install, 1000)
  end,
})
