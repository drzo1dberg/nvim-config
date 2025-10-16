if vim.g.__obsidian_week_cmd_defined then
	return
end
vim.g.__obsidian_week_cmd_defined = true

vim.api.nvim_create_user_command("ObsidianThisWeek", function()
	local ok, obsidian = pcall(require, "obsidian")
	if not ok then
		vim.notify("obsidian.nvim noch nicht geladen", vim.log.levels.WARN)
		return
	end

	local y = os.date("%G") -- ISO-Jahr
	local w = os.date("%V") -- ISO-KW (01..53)

	local rel_dir = string.format("daily todos/%s/kw%s", y, w)
	local rel_file = string.format("%s/kw%s.md", rel_dir, w)

	local client = obsidian.get_client()
	local root = client:vault_root()

	local Path = require("obsidian.path")
	local root_path = Path.new(root)

	local abs_dir = root_path / rel_dir
	local abs_file = root_path / rel_file

	if not abs_dir:exists() then
		abs_dir:mkdir({ parents = true })
	end

	if not abs_file:exists() then
		abs_file:write(("# Week %s (%s)\n\n- [ ] TODOs\n\n"):format(w, y))
	end

	vim.cmd.edit(tostring(abs_file))
end, {})
