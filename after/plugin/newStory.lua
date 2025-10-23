if vim.g.__obsidian_new_story_defined then
	return
end
vim.g.__obsidian_new_story_defined = true

local ok, mod = pcall(require, "obsidian_story")
if not ok then
	vim.notify("obsidian_story Modul nicht gefunden (lua/obsidian_story/init.lua?)", vim.log.levels.ERROR)
	return
end

vim.api.nvim_create_user_command("ObsidianNewStory", mod.commands.new_story, {})
