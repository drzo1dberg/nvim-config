if vim.g.__obsidian_new_short_numbered_defined then
	return
end
vim.g.__obsidian_new_short_numbered_defined = true
local ok, mod = pcall(require, "obsidian_story")
if not ok then
	vim.notify("obsidian_story Modul fehlt", vim.log.levels.ERROR)
	return
end
vim.api.nvim_create_user_command("ObsidianNewShortNumbered", mod.commands.new_short_numbered, {})
