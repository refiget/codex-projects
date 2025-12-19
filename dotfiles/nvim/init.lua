-- ===================== init.lua =====================
-- 只负责加载各模块，逻辑分散到 lua/user 下
require("user.core")        -- env/options/autocmds
require("user.clipboard")   -- tmux+OSC52 提供者
require("user.plugins")     -- 插件与插件配置
require("user.coc").setup() -- Coc 扩展列表
require("user.keymaps")     -- 基础按键
require("user.snippets")    -- LuaSnip + 补全相关按键
