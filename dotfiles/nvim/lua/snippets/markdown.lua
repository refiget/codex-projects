-- Auto-migrated LaTeX Suite snippets (Obsidian -> LuaSnip)
-- 全部作为 autosnippet，Markdown 文件内使用；math 相关仅在数学环境展开。

local ls = require("luasnip")
local s = ls.snippet
local p = require("luasnip.extras").partial
local ps = ls.parser.parse_snippet
local f = ls.function_node

-- 简易数学环境判断（未依赖 vimtex）
local function in_math()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)
  local function count(str, pat)
    local n, i = 0, 1
    while true do
      local s1, e1 = str:find(pat, i)
      if not s1 then break end
      if not (s1 > 1 and str:sub(s1 - 1, s1 - 1) == "\\") then
        n = n + 1
      end
      i = e1 + 1
    end
    return n
  end
  local double = count(before, "%$%$")
  if double % 2 == 1 then return true end
  local single = count(before:gsub("%$%$", ""), "%$")
  return single % 2 == 1
end

local function cond_math() return in_math() end
local function cond_text() return not in_math() end

-- 工具：批量生成非正则触发的 snippet
local function literal(trig, body, opts)
  opts = opts or {}
  local cond = nil
  if opts.math then cond = cond_math end
  if opts.text then cond = cond_text end
  -- 数学模式默认不要求单词边界，便于 xun 直接触发下划线等；文本保持单词边界。
  local word_trig = opts.wordTrig
  if word_trig == nil then
    word_trig = not opts.math
  end
  return ps({
    trig = trig,
    wordTrig = word_trig,
    snippetType = "autosnippet",
    condition = cond,
  }, body)
end

-- 规则表：仅包含非正则触发（regex 规则需手写 f-node，待后续补充）
local rules = {
  { "for", "\\forall", "m" }, { "circ", "\\circ", "m" }, { "in", "\\in", "m" },
  { "rsum", "\\sum", "m" }, { "un", "_{$0}", "m" }, { "eq", "=", "m" },
  { "tec", "\\textcolor{red}{$0}", "m" }, { "hom", "Hom_R(M$0,N) ", "m" },
  { "xra", "\\xrightarrow{$0} ", "m" }, { "nspace", "(X,\\| \\cdot \\|) ", "m" },
  { "xn", "x_{n} ", "m" }, { "@r", "\\rho ", "m" }, { "yn", "y_{n} ", "m" },
  { "zn", "z_{n} ", "m" },
  -- Math mode explicit（mk/dm 不限制条件，便于随时建立环境）
  { "mk", "$$0$", "!" }, { "MK", "$$0$", "!" }, { "mK", "$$0$", "!" }, { "Mk", "$$0$", "!" },
  { "dm", "$$\n$0\n$$", "!" }, { "beg", "\\begin{$0}\n$1\n\\end{$0}", "m" },
  -- Greek shortcuts
  { "@a", "\\alpha", "m" }, { "@b", "\\beta", "m" }, { "@g", "\\gamma", "m" }, { "@G", "\\Gamma", "m" },
  { "@d", "\\delta", "m" }, { "@D", "\\Delta", "m" }, { "@e", "\\varepsilon", "m" }, { ":e", "\\varepsilon", "m" },
  { "@z", "\\zeta", "m" }, { "@f", "\\varphi", "m" }, { "@t", "\\theta", "m" }, { "@T", "\\Theta", "m" },
  { ":t", "\\vartheta", "m" }, { "rho", "\\rho", "m" }, { "@i", "\\iota", "m" }, { "@k", "\\kappa", "m" },
  { "@l", "\\lambda", "m" }, { "@L", "\\Lambda", "m" }, { "@s", "\\sigma", "m" }, { "@S", "\\Sigma", "m" },
  { "@u", "\\upsilon", "m" }, { "@U", "\\Upsilon", "m" }, { "@o", "\\omega", "m" }, { "@O", "\\Omega", "m" },
  { "ome", "\\omega", "m" }, { "Ome", "\\Omega", "m" },
  -- Text env
  { "text", "\\text{$0}$1", "m" }, { "\"", "\\text{$0}$1", "m" },
  -- Basic ops
  { "sr", "^{2}", "m" }, { "cb", "^{3}", "m" }, { "rd", "^{$0}$1", "m" }, { "_", "_{$0}$1", "m" },
  { "sts", "_\\text{$0}", "m" }, { "//", "\\frac{$0}{$1}$2", "m" }, { "ee", "e^{ $0 }$1", "m" },
  { "invs", "^{-1}", "m" }, { "conj", "^{*}", "m" }, { "Re", "\\mathrm{Re}", "m" }, { "Im", "\\mathrm{Im}", "m" },
  { "bb", "\\mathbb{$0}", "m" }, { "scr", "\\mathscr{$0}", "m" },
  { "hat", "\\hat{$0}$1", "m" }, { "bar", "\\bar{$0}$1", "m" }, { "dot", "\\dot{$0}$1", "m" }, { "ddot", "\\ddot{$0}$1", "m" },
  { "cdot", "\\cdot", "m" }, { "tilde", "\\tilde{$0}$1", "m" }, { "und", "\\underline{$0}$1", "m" }, { "vec", "\\vec{$0}$1", "m" },
  { "xnn", "x_{n}", "m" }, { "xjj", "x_{j}", "m" }, { "xp1", "x_{n+1}", "m" },
  { "ynn", "y_{n}", "m" }, { "yii", "y_{i}", "m" }, { "yjj", "y_{j}", "m" },
  { "ooo", "\\infty", "m" }, { "sum", "\\sum_{i=1}^{N}", "m" }, { "prod", "\\prod", "m" }, { "suf", "\\sum_{n=1}^{\\infty}", "m" },
  { "lim", "\\lim_{ ${0:n} \\to ${1:\\infty} } $2", "m" }, { "+-", "\\pm", "m" }, { "-+", "\\mp", "m" },
  { "...", "\\dots", "m" }, { "nabl", "\\nabla", "m" }, { "del", "\\nabla", "m" }, { "xx", "\\times", "m" }, { "**", "\\cdot", "m" },
  { "para", "\\parallel", "m" }, { "===", "\\equiv", "m" }, { "!=", "\\neq", "m" }, { ">=", "\\geq", "m" }, { "<=", "\\leq", "m" },
  { ">>", "\\gg", "m" }, { "<<", "\\ll", "m" }, { "simm", "\\sim", "m" }, { "sim=", "\\simeq", "m" }, { "prop", "\\propto", "m" },
  { "lra", "\\Longleftrightarrow ", "m" }, { "to", "\\to", "m" }, { "!>", "\\mapsto", "m" }, { "=>", "\\implies", "m" }, { "=<", "\\impliedby", "m" },
  { "and", "\\cap", "m" }, { "orr", "\\cup", "m" }, { "inn", "\\in", "m" }, { "notin", "\\not\\in", "m" }, { "\\\\", "\\setminus", "m" },
  { "sub=", "\\subset", "m" }, { "sup=", "\\supset", "m" }, { "eset", "\\emptyset", "m" }, { "set", "\\{ $0 \\}$1", "m" },
  { "exi", "\\exists", "m" }, { "LL", "\\mathcal{L}", "m" }, { "HH", "\\mathcal{H}", "m" }, { "CC", "\\mathbb{C}", "m" },
  { "RR", "\\mathbb{R}", "m" }, { "ZZ", "\\mathbb{Z}", "m" }, { "NN", "\\mathbb{N}", "m" },
  -- Derivatives / integrals
  { "par", "\\frac{ \\partial ${0:y} }{ \\partial ${1:x} } $2", "m" },
  { "ddt", "\\frac{d}{dt} ", "m" }, { "dint", "\\int_{${0:0}}^{${1:1}} $2 \\, d${3:x} $4", "m" },
  { "oint", "\\oint", "m" }, { "iint", "\\iint", "m" }, { "iiint", "\\iiint", "m" },
  { "oinf", "\\int_{0}^{\\infty} $0 \\, d${1:x} $2", "m" }, { "infi", "\\int_{-\\infty}^{\\infty} $0 \\, d${1:x} $2", "m" },
  -- Visual operations
  { "U", "\\underbrace{ ${VISUAL} }_{ $0 }", "m" }, { "O", "\\overbrace{ ${VISUAL} }^{ $0 }", "m" },
  { "B", "\\underset{ $0 }{ ${VISUAL} }", "m" }, { "C", "\\cancel{ ${VISUAL} }", "m" }, { "K", "\\cancelto{ $0 }{ ${VISUAL} }", "m" },
  -- Physics / QM
  { "kbt", "k_{B}T", "m" }, { "msun", "M_{\\odot}", "m" }, { "dag", "^{\\dagger}", "m" },
  { "o+", "\\oplus ", "m" }, { "ox", "\\otimes ", "m" },
  { "bra", "\\bra{$0} $1", "m" }, { "ket", "\\ket{$0} $1", "m" }, { "brk", "\\braket{ $0 | $1 } $2", "m" },
  { "outer", "\\ket{${0:\\psi}} \\bra{${0:\\psi}} $1", "m" },
  -- Chemistry
  { "cee", "\\ce{ $0 }", "m" }, { "he4", "{}^{4}_{2}He ", "m" }, { "he3", "{}^{3}_{2}He ", "m" },
  { "iso", "{}^{${0:4}}_{${1:2}}${2:He}", "m" },
  -- Environments
  { "pmat", "\\begin{pmatrix}\n$0\n\\end{pmatrix}", "m" },
  { "bmat", "\\begin{bmatrix}\n$0\n\\end{bmatrix}", "m" },
  { "Bmat", "\\begin{Bmatrix}\n$0\n\\end{Bmatrix}", "m" },
  { "vmat", "\\begin{vmatrix}\n$0\n\\end{vmatrix}", "m" },
  { "Vmat", "\\begin{Vmatrix}\n$0\n\\end{Vmatrix}", "m" },
  { "matrix", "\\begin{matrix}\n$0\n\\end{matrix}", "m" },
  { "cases", "\\begin{cases}\n$0\n\\end{cases}", "m" },
  { "align", "\\begin{align}\n$0\n\\end{align}", "m" },
  { "array", "\\begin{array}\n$0\n\\end{array}", "m" },
  -- Brackets
  { "avg", "\\langle $0 \\rangle $1", "m" }, { "norm", "\\| $0 \\| $1", "m" }, { "Norm", "\\lVert $0 \\rVert $1", "m" },
  { "ceil", "\\lceil $0 \\rceil $1", "m" }, { "floor", "\\lfloor $0 \\rfloor $1", "m" },
  { "rvt", "|0 \\rangle", "m" }, { "lvt", "\\langle 0|", "m" }, { "mod", "|$0|$1", "m" },
  { "lr(", "\\left( $0 \\right) $1", "m" }, { "lr{", "\\left\\{ $0 \\right\\} $1", "m" }, { "lr[", "\\left[ $0 \\right] $1", "m" },
  { "lr|", "\\left| $0 \\right| $1", "m" }, { "lra", "\\left< $0 \\right> $1", "m" },
  -- metric space
  { "mspace", "(X,\\rho)", "m" }, { "mxy", "\\rho(x,y)", "m" }, { "nmspace", "(X_{${1:n}},\\rho_{${1:n}})", "m" },
  { "lxn", "\\left\\{ x_{${1:n}} \\right\\}", "m" }, { "lyn", "\\left\\{ y_{${1:n}} \\right\\}", "m" },
  { "@n", "\\eta", "m" },
  -- Taylor
  { "tayl", "${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3", "m" },
}

local snippets = {}
for _, r in ipairs(rules) do
  local trig, body, opt = r[1], r[2], r[3] or ""
  local math_cond = opt:find("m") ~= nil or opt:find("M") ~= nil
  local text_cond = opt:find("t") ~= nil
  local force_anywhere = opt:find("!") ~= nil   -- 显式强制无边界触发
  table.insert(snippets, literal(trig, body, {
    math = math_cond,
    text = text_cond,
    wordTrig = force_anywhere and false or nil,
  }))
end

-- Regex-heavy/visual snippets尚未逐条转 LuaSnip；若需补齐可再扩展。

ls.add_snippets("markdown", snippets, { key = "markdown-latexsuite-auto" })
