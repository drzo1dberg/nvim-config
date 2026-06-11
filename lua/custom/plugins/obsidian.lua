return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "work",
				path = "/mnt/c/Users/drzo1dberg/OneDrive - Example GmbH/Dokumente/Example/",
				templates = {
					folder = "Vorlagen",
					date_format = "%Y-%m-%d",
					time_format = "%H:%M",
				},
			},
		},

		note_path_func = function(spec)
			local function sanitize(s)
				s = (s or "")
					:gsub("%c", "")
					:gsub('[<>:"/\\|%?%*]', "")
					:gsub("^%s+", "")
					:gsub("%s+$", "")
				s = s:gsub(":", ".")
				return s
			end

			local function has_tag(tags, want)
				for _, t in ipairs(tags or {}) do
					if t == want then return true end
				end
				return false
			end

			local title = sanitize(spec.title)
			if title == "" then
				title = "note-" .. (spec.id and spec.id:sub(1, 6) or os.date("%H%M%S"))
			end

			if has_tag(spec.tags, "adr") then
				return "Architektur Decision Record/" .. title
			elseif has_tag(spec.tags, "zettel") then
				return "Zettelkasten/" .. title
			end

			local y = os.date("%G")
			local w = os.date("%V")
			return string.format("daily todos/%s/kw%s/%s", y, w, title)
		end,

		note_frontmatter_func = function(note)
			local today = os.date("%Y-%m-%d")
			local existing = note.metadata or {}
			local fm = {
				id = note.id,
				title = note.title,
				tags = note.tags,
				aliases = note.aliases,
				created = existing.created or today,
				updated = today,
			}
			for k, v in pairs(existing) do
				if fm[k] == nil then fm[k] = v end
			end
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

	config = function(_, opts)
		require("obsidian").setup(opts)

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.md",
			callback = function(args)
				local path = vim.api.nvim_buf_get_name(args.buf)
				if not path:find("Example", 1, true) then return end

				local lines = vim.api.nvim_buf_get_lines(args.buf, 0, 30, false)
				if lines[1] ~= "---" then return end

				local today = os.date("%Y-%m-%d")
				for i = 2, #lines do
					if lines[i] == "---" then return end
					if lines[i]:match("^updated:%s*") then
						vim.api.nvim_buf_set_lines(args.buf, i - 1, i, false,
							{ "updated: " .. today })
						return
					end
				end
			end,
		})
	end,
}
