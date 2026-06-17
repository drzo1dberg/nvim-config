-- Vault-Pfad: pro Maschine ueber ~/.config/obsidian-vault gesetzt, eine Zeile mit
-- dem Pfad, geschrieben von install.sh --obsidian-location. Dieselbe Datei steuert
-- die Shell-Aliases vl und vault. Fehlt sie, gilt der neutrale Default ~/obsidian
-- und das Plugin bleibt per cond aus, bis ein echter Vault konfiguriert ist.
local vault = vim.fn.expand("~/obsidian")
local override = vim.fn.expand("~/.config/obsidian-vault")
if vim.fn.filereadable(override) == 1 then
	local lines = vim.fn.readfile(override, "", 1)
	if lines[1] and lines[1] ~= "" then
		vault = lines[1]
	end
end

return {
	-- gepflegter Community-Fork, Upstream von epwalsh ist archiviert
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	-- nur laden, wenn der Work-Vault gemountet ist; auf Maschinen ohne ihn bleibt das Plugin aus
	cond = function()
		return vim.fn.isdirectory(vault) == 1
	end,
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "work",
				path = vault,
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

		-- img_folder MUSS ein String sein, das Plugin macht Path.new() darauf.
		-- Statischer Fallback, der KW-Pfad wird vor dem Einfuegen dynamisch gesetzt.
		attachments = {
			img_folder = "daily todos/assets",
		},
		-- image_name_func liegt auf der obersten opts-Ebene, nur dort liest das
		-- Plugin sie (siehe commands/paste_img.lua), nicht unter attachments.
		image_name_func = function()
			return string.format("img_%s", os.date("%Y%m%d-%H%M%S"))
		end,

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

		-- Bild in den KW-Ordner der aktuellen Woche einfuegen. img_folder muss
		-- ein String sein, daher wird der Wochenpfad zur Laufzeit auf dem Client
		-- gesetzt, bevor der normale Paste-Command laeuft.
		vim.api.nvim_create_user_command("ObsidianImgWeek", function()
			local ok, obs = pcall(require, "obsidian")
			if not ok then return end
			obs.get_client().opts.attachments.img_folder =
				string.format("daily todos/%s/kw%s", os.date("%G"), os.date("%V"))
			vim.cmd("ObsidianPasteImg")
		end, { desc = "Obsidian: Bild in den KW-Ordner der Woche einfuegen" })
		vim.keymap.set("n", "<leader>oi", "<cmd>ObsidianImgWeek<cr>",
			{ desc = "Obsidian: Bild in KW-Ordner einfuegen" })

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.md",
			callback = function(args)
				local path = vim.api.nvim_buf_get_name(args.buf)
				-- nur Dateien innerhalb des konfigurierten Vaults anfassen
				if not path:find(vault, 1, true) then return end

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
