-- ~/.config/nvim/after/ftplugin/markdown.lua
------------------------------------------------
-- 1) Obsidian-UI einschalten
vim.opt_local.conceallevel = 2 -- 1 zeigt Platzhalterpunkte, 2 gar nichts
vim.opt_local.concealcursor = "" -- im Normal- & Insert-Mode verdecken

-- 2) Linter/Diagnostics für Markdown komplett abschalten
local ok, lint = pcall(require, "lint")
if ok then
	lint.linters_by_ft.markdown = {} -- nvim-lint ruft nichts mehr
end
vim.diagnostic.enable(false, { bufnr = 0 }) -- nur fuer diesen Buffer, sonst global aus
------------------------------------------------
