-- Luacheck-Konfiguration fuer die Neovim-Config (kickstart-basiert).
-- LuaJIT entspricht Lua 5.1, daher dieser Standard.
std = "luajit"
codes = true

-- vim wird von Neovim zur Laufzeit als globale Tabelle bereitgestellt.
globals = {
  "vim",
}

-- Warnungs-Codes: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
  "212", -- ungenutztes Argument, bei Callbacks meist gewollt
  "122", -- indirektes Setzen eines readonly-Globals, z. B. vim.opt
}
