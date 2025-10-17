return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
<<<<<<< HEAD
				path = "/mnt/c/Users/MichaelJNunesJacobsG/OneDrive - Grothe IT-Service GmbH/Dokumente/privat/",
			},
			{
				name = "work",
				path = "/mnt/c/Users/MichaelJNunesJacobsG/OneDrive - Grothe IT-Service GmbH/Dokumente/Grothe IT-Service/",
			},
			{
				name = "anywhere",
				path = function()
					return assert(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
				end,
				overrides = {
					notes_subdir = vim.NIL,
					new_notes_location = "current_dir",
					templates = { folder = vim.NIL },
					disable_frontmatter = true,
				},
			},
		},
		daily_notes = {
			folder = "daily todos",
			default_tags = { "daily-todo" },
		},
		attachments = {
			img_folder = "daily todos",
			image_name_func = function()
				local y = os.date("%G") -- ISO-Jahr (Kalenderwochenjahr)
				local w = os.date("%V") -- ISO-KW (01..53)
				return string.format("%s/kw%s/img_%s", y, w, os.date("%Y%m%d-%H%M%S"))
			end,
		},
		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
=======
				path = "/home/michael/obsidian/",
>>>>>>> a14cb6f (personal setup)
			},
		},
	},
}
