-- Luacheck-Konfiguration fuer die Neovim-Config (kickstart-basiert).
-- LuaJIT entspricht Lua 5.1, daher dieser Standard.
std = "luajit"
codes = true

-- vim wird von Neovim zur Laufzeit als globale Tabelle bereitgestellt.
-- Obsidian setzt obsidian.nvim beim Setup als globale Tabelle, daran haengen
-- der aktive Workspace und seine Optionen.
globals = {
  "vim",
  "Obsidian",
}

-- Warnungs-Codes: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
  "212", -- ungenutztes Argument, bei Callbacks meist gewollt
  "122", -- indirektes Setzen eines readonly-Globals, z. B. vim.opt
}
