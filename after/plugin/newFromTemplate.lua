if vim.g.__obsidian_new_from_template_defined then
	return
end
vim.g.__obsidian_new_from_template_defined = true

local ok, mod = pcall(require, "obsidian_story")
if not ok then
	vim.notify("obsidian_story Modul nicht gefunden", vim.log.levels.ERROR)
	return
end

vim.api.nvim_create_user_command("ObsidianNewFromTemplate", mod.commands.new_from_template, {})
