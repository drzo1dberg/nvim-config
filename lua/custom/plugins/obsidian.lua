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
				name = "work",
				path = "/mnt/c/Users/MichaelJNunesJacobsG/OneDrive - Grothe IT-Service GmbH/Dokumente/Grothe IT-Service/",
				templates = {
					folder = "templates", -- /home/obsidian/templates
					date_format = "%Y-%m-%d",
					time_format = "%H:%M",
				},
			},
		},
		note_path_func = function(spec)
			local function sanitize(s)
				s = (s or "")
					:gsub("%c", "") --control chars
					:gsub('[<>:"/\\|%?%*]', "") -- forbidden signs
					:gsub("^%s+", "")
					:gsub("%s+$", "") -- Trim
				s = s:gsub(":", ".") -- : to .
				return s
			end

			local y = os.date("%G")
			local w = os.date("%V")
			local base = string.format("daily todos/%s/kw%s/", y, w)

			local title = sanitize(spec.title)
			if title == "" then
				title = "note-" .. (spec.id and spec.id:sub(1, 6) or os.date("%H%M%S"))
			end
			return base .. title
		end,

		note_frontmatter_func = function(note)
			local fm = {
				id = note.id,
				title = note.title,
				tags = note.tags,
				aliases = note.aliases,
			}
			return fm
		end,

		daily_notes = {
			folder = "daily todos",
			default_tags = { "daily-todo" },
		},

		attachments = {
			img_folder = function()
				local y = os.date("%G")
				local w = os.date("%V")
				return string.format("daily todos/%s/kw%s", y, w)
			end,
			image_name_func = function()
				return string.format("img_%s", os.date("%Y%m%d-%H%M%S"))
			end,
		},

		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
		},
	},
}
