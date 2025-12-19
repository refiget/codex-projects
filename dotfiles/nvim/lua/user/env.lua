-- ===================== env.lua =====================
local fn = vim.fn

vim.env.PYTHONWARNINGS = "ignore::SyntaxWarning"
if fn.isdirectory(fn.getcwd()) == 0 then
  vim.cmd("cd ~")
end

local function detect_python_host()
  local candidates = {
    fn.expand("~/venvs/nvim/bin/python3"),
    fn.expand("~/.venvs/nvim/bin/python3"),
    "/usr/local/opt/python@3/bin/python3",
    "/opt/homebrew/bin/python3",
    "/usr/local/bin/python3",
    "/usr/bin/python3",
  }
  for _, path in ipairs(candidates) do
    if fn.executable(path) == 1 then
      return path
    end
  end
  return "python3"
end

vim.g.python3_host_prog = detect_python_host()
