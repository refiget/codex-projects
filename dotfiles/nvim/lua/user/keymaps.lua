-- ===================== keymaps.lua =====================
vim.g.mapleader = " "
local keymap = vim.keymap.set
local opts = { silent = true }

-- Basic
keymap("n", ";", ":", { desc = "Command mode" })
keymap("n", "Q", ":q<CR>", opts)
keymap("n", "Y", '"+yy', opts)     -- 行复制到系统剪贴板
keymap("v", "Y", '"+y', opts)      -- 选区复制到系统剪贴板
keymap("n", "<leader><CR>", ":nohlsearch<CR>", opts)

-- Advanced
keymap("n", "J", "5j", opts)
keymap("n", "K", "5k", opts)

-- Splits
keymap("n", "s", "<nop>")

keymap("n", "<leader>l", "<C-w>l", opts)
keymap("n", "<leader>k", "<C-w>k", opts)
keymap("n", "<leader>j", "<C-w>j", opts)
keymap("n", "<leader>h", "<C-w>h", opts)

-- File tree (coc-explorer)
keymap("n", "<leader>e", ":CocCommand explorer<CR>", { silent = true, noremap = true, desc = "Open file explorer" })

-- Markdown preview (browser)
keymap("n", "<leader>mp", ":MarkdownPreview<CR>", { silent = true, noremap = true, desc = "Markdown preview" })
keymap("n", "<leader>mP", ":MarkdownPreviewStop<CR>", { silent = true, noremap = true, desc = "Markdown preview stop" })

-- Tabs: 原生 gt/gT，支持循环切换，数字前缀生效
local function tab_cycle(delta)
  local total = vim.fn.tabpagenr("$")
  if total <= 1 then
    return
  end
  local current = vim.fn.tabpagenr()
  local count = vim.v.count1
  local target = ((current - 1 + delta * count) % total) + 1
  vim.cmd("tabnext " .. target)
end

keymap("n", "gt", function()
  tab_cycle(1)
end, { silent = true, noremap = true, desc = "Tab next (wrap)" })

keymap("n", "gT", function()
  tab_cycle(-1)
end, { silent = true, noremap = true, desc = "Tab prev (wrap)" })


-- Coc.nvim format --
vim.keymap.set(
  "n",
  "<leader>f",
  ":CocCommand editor.action.formatDocument<CR>",
  { silent = true, noremap = true, desc = "Format document with Coc" }
)
keymap("n", "cr", "<Plug>(coc-rename)", { silent = true })
-- Markdown + Wrap toggle
keymap("n", "<leader>sw", ":set wrap!<CR>", { desc = "Toggle wrap" })
vim.keymap.set(
  "i",
  "<CR>",
  'pumvisible() ? coc#_select_confirm() : "<CR>"',
  { noremap = true, silent = true, expr = true }
)


-- Compile/Run
-- Python-only Run
local function run_python()
  vim.cmd("w")  -- save file
  local file = vim.fn.expand("%")

  -- Use term but avoid split issues on SSH
  vim.cmd("botright 10split | term python3 " .. file)
end

-- Map to "r"
keymap("n", "r", run_python, { silent = true, desc = "Run Python file" })


-- Terminal
keymap("t", "<C-N>", "<C-\\><C-N>", opts)
-- ===================== Delete behavior enhancements =====================

-- ① d / D —— 正常删除（写入默认寄存器 "）
keymap({ "n", "x" }, "d", "d", opts)
keymap({ "n", "x" }, "D", "D", opts)

-- ② x / X —— 删一个字符，不污染寄存器（写入黑洞寄存器 "_）
keymap("n", "x", '"_x', opts)
keymap("n", "X", '"_X', opts)

-- ③ c / C —— 修改也不写入寄存器（防止干扰 y）
keymap("n", "c", '"_c', opts)
keymap("n", "C", '"_C', opts)
keymap("x", "c", '"_c', opts)
keymap("x", "C", '"_C', opts) 


-------------------------------------------------
-- DeepSeek CLI 集成（Neovim 内置 terminal 版本）
-------------------------------------------------

-- DeepSeek CLI 路径：可通过环境变量覆盖
local function resolve_ds_cli()
  local sysname = vim.loop.os_uname().sysname or ""
  local default_root = sysname == "Darwin" and "~/Projects/deepseek-cli" or "~/projects/deepseek-cli"
  local root = vim.fn.expand(vim.env.DS_CLI_ROOT or default_root)
  local cmd = vim.fn.expand(vim.env.DS_CLI_CMD or (root .. "/ds"))
  if vim.fn.executable(cmd) == 1 then
    return root, cmd
  end
  return root, nil
end

local DS_CMD_ROOT, DS_CMD = resolve_ds_cli()

local function ensure_ds_cmd()
  if DS_CMD and vim.fn.executable(DS_CMD) == 1 then
    return true
  end
  vim.notify(
    "DeepSeek CLI 未找到，可设置 DS_CLI_ROOT/DS_CLI_CMD；当前尝试路径: " .. (DS_CMD or "未检测到"),
    vim.log.levels.WARN,
    { title = "DeepSeek CLI" }
  )
  return false
end

-- 在右侧新建一个终端窗口，流式运行命令
local function open_ds_term(cmd)
  if not ensure_ds_cmd() then
    return
  end
  -- 在右侧竖分屏中新建一个空窗口
  vim.cmd("botright vnew")

  -- 获取当前窗口，用来设置宽度
  local win = vim.api.nvim_get_current_win()

  -- 在这个新窗口 / buffer 里打开终端
  vim.fn.termopen({ "bash", "-lc", "cd " .. DS_CMD_ROOT .. " && " .. cmd })

  -- 右侧窗口宽度，可按需要调整
  vim.api.nvim_win_set_width(win, 50)

  -- 进入插入模式方便看输出
  vim.cmd("startinsert")
end

-- 获取可视模式选区文本
local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))
  if ls > le or (ls == le and cs > ce) then
    ls, le = le, ls
    cs, ce = ce, cs
  end
  local lines = vim.fn.getline(ls, le)
  if #lines == 0 then
    return ""
  end
  lines[#lines] = string.sub(lines[#lines], 1, ce)
  lines[1] = string.sub(lines[1], cs)
  return table.concat(lines, "\n")
end

-------------------------------------------------
-- 1) 在 Neovim 里向 DeepSeek 提问（普通问答）
--    普通模式按：<leader>dq   （空格 d q）
-------------------------------------------------
local function ds_ask_in_term()
  local q = vim.fn.input("DeepSeek（请直接问）> ")
  if q == nil or q == "" then
    return
  end
  
  -- 添加简洁指令
  local concise_q = "请用最简洁的方式回答，直接给答案，不要解释过程，不要用礼貌用语：" .. q
  
  local esc = vim.fn.shellescape(concise_q)
  if ensure_ds_cmd() then
    local cmd = DS_CMD .. " " .. esc
    open_ds_term(cmd)
  end
end

vim.keymap.set(
  "n",
  "<leader>dq",
  ds_ask_in_term,
  { silent = true, noremap = true, desc = "DeepSeek: ask question (terminal)" }
)

-------------------------------------------------
-- 2) 选中一段代码让 DeepSeek 查错 + 给修改建议
--    可视模式按：<leader>dr   （空格 d r）
-------------------------------------------------
local function ds_review_visual_in_term()
  local code = get_visual_selection()
  if code == nil or code == "" then
    vim.notify("No visual selection", vim.log.levels.WARN, { title = "DeepSeek Review" })
    return
  end

  local ft = vim.bo.filetype
  local lang = (ft ~= "" and ft or "代码")

  -- 优化后的简洁 prompt
  local prompt = table.concat({
    "直接指出以下" .. lang .. "代码的问题，给出修改后的代码。",
    "要求：1. 列出关键问题（不超过3点） 2. 直接给出修改后的代码 3. 不要解释原理",
    "",
    "代码：",
    code,
    "",
    "请按这个格式回答：[问题列表] [修改后的代码]"
  }, "\n")

  local esc = vim.fn.shellescape(prompt)
  if ensure_ds_cmd() then
    local cmd = DS_CMD .. " " .. esc
    open_ds_term(cmd)
  end
end

vim.keymap.set(
  "v",
  "<leader>dr",
  ds_review_visual_in_term,
  { silent = true, noremap = true, desc = "DeepSeek: review selected code (terminal)" }
)

-------------------------------------------------
-- 3) 生成 doctest 示例并插入当前缓冲区
--    普通模式按：<leader>dt   （空格 d t）
-------------------------------------------------
local function ds_doctest_current_buffer()
  -- 把当前 buffer 的所有内容拼成一段文本
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local buf_text = table.concat(buf_lines, "\n")
  if buf_text == "" then
    vim.notify("当前缓冲区为空，无法生成 doctest", vim.log.levels.WARN, { title = "DeepSeek Doctest" })
    return
  end

  local prompt = table.concat({
    "你是 Python 助教，请基于下面的代码编写 doctest 示例。",
    "只返回 doctest 片段：包含函数调用、输入与预期输出，不要解释，不要其他文字。",
    buf_text,
  }, "\n")

  local esc = vim.fn.shellescape(prompt)
  local cmd = "cd " .. DS_CMD_ROOT .. " && " .. DS_CMD .. " " .. esc
  local output = vim.fn.system({ "bash", "-lc", cmd })

  if vim.v.shell_error ~= 0 or output == nil or output == "" then
    vim.notify("DeepSeek doctest 生成失败", vim.log.levels.ERROR, { title = "DeepSeek Doctest" })
    return
  end

  -- 过滤 ANSI 颜色、主题说明、Markdown 代码围栏
  local function clean_lines(raw)
    local cleaned = {}
    for _, line in ipairs(raw) do
      line = line:gsub("\27%[[0-9;]*m", "")  -- ESC 开头
      line = line:gsub("%[[0-9;]*m", "")     -- 部分 CLI 直接渲染出的 [90m 形式
      if not line:match("^```") and not line:match("^%s*%-%-%-") then
        table.insert(cleaned, line)
      end
    end
    return cleaned
  end

  local cleaned = clean_lines(vim.split(output, "\n", { plain = true, trimempty = true }))

  if #cleaned == 0 then
    vim.notify("未获取到可插入的 doctest 内容", vim.log.levels.WARN, { title = "DeepSeek Doctest" })
    return
  end

  local function get_shiftwidth()
    local sw = vim.bo.shiftwidth
    if sw == 0 or sw == nil then
      sw = vim.o.shiftwidth
    end
    if sw == 0 or sw == nil then
      sw = 2
    end
    return sw
  end

  -- 忽略光标，尽量把 doctest 放到第一个 def/class 等块的内部（下一层缩进）
  local function decide_insert_pos()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      local trimmed = vim.trim(line)
      if trimmed ~= "" and trimmed:sub(-1) == ":" then
        local base_indent = line:match("^(%s*)") or ""
        local indent = base_indent .. string.rep(" ", get_shiftwidth())
        return i, indent  -- i 是 0-based，插在该行之后
      end
    end
    return 0, ""  -- 没找到块，放到文件开头，无缩进
  end

  local insert_row, indent = decide_insert_pos()

  local function with_indent(line)
    if indent == "" then
      return line
    end
    if line == "" then
      return indent
    end
    return indent .. line
  end

  local insert_lines = { with_indent('"""') }
  for _, line in ipairs(cleaned) do
    table.insert(insert_lines, with_indent(line))
  end
  table.insert(insert_lines, with_indent('"""'))

  vim.api.nvim_buf_set_lines(0, insert_row + 1, insert_row + 1, false, insert_lines)
end

vim.keymap.set(
  "n",
  "<leader>dt",
  ds_doctest_current_buffer,
  { silent = true, noremap = true, desc = "DeepSeek: generate doctest for buffer" }
)


-- ===================== Telescope: Projects + dotfiles 文件搜索 =====================
vim.keymap.set("n", "<leader>w", function()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("Telescope 未安装或加载失败", vim.log.levels.WARN, { title = "Telescope" })
    return
  end

  local projects = vim.fn.expand("~/Projects")
  local dotfiles = vim.fn.expand("~/dotfiles")

  builtin.find_files({
    -- 同时在 Projects 和 dotfiles 里搜
    search_dirs = { projects, dotfiles },
    hidden = true,  -- 包含隐藏文件（.gitignore 之类）
    
    -- 添加这个配置，让文件在新标签页打开
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local function open_path(cmd)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.path then
          vim.cmd({ cmd = cmd, args = { selection.path } })
        end
      end

      -- 覆盖默认的打开方式，i/n 模式一致
      map({ "i", "n" }, "<CR>", function()
        open_path("tabe")
      end)
      
      -- 保持其他快捷键
      map({ "i", "n" }, "<C-v>", function()
        open_path("vsplit")
      end)
      
      map({ "i", "n" }, "<C-x>", function()
        open_path("split")
      end)
      
      return true
    end,
  })
end, { silent = true, noremap = true, desc = "Telescope: find file in Projects + dotfiles (open in new tab)" })
