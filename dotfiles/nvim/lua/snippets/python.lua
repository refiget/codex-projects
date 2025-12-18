local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- 触发词：doctmain
  -- 用法：在 Python 文件里，插入模式输入 doctmain 然后按 <Tab>（你当前的 LuaSnip 映射）
  s("doctest", {
    t('if __name__ == "__main__":'),
    t({ "", "    import doctest" }),
    t({ "", "    doctest.testmod(verbose=" }),
    i(1, "True"),
    t(")"),
  }),
}
