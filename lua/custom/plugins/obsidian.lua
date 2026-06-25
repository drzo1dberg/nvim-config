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

-- Zweiter Workspace: der ganze Code-Bereich ~/github-repos. Pfad bewusst fest und
-- maschinenunabhaengig, dieselbe Konvention nutzt install.sh schon fuer zk-archive.
-- Damit bleibt die Config ueber install.sh auf jeder Maschine identisch nutzbar:
-- existiert der Ordner, ist der Workspace aktiv, sonst bleibt er lautlos aus.
-- notes/ und daily/ legt obsidian.nvim beim ersten Aktivieren selbst an.
local repos = vim.fn.expand("~/github-repos")

local has_vault = vim.fn.isdirectory(vault) == 1
local has_repos = vim.fn.isdirectory(repos) == 1

-- Dateinamen-Hygiene, geteilt von beiden note_path_func.
local function sanitize(s)
	s = (s or "")
		:gsub("%c", "")
		:gsub('[<>:"/\\|%?%*]', "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
	s = s:gsub(":", ".")
	return s
end

-- Frontmatter im Repo-Bereich nur fuer echte Notizen unter notes/ und daily/.
-- Bestehende Repo-Doku wie docs/ oder ARCHITECTURE.md wird beim Speichern nie
-- angefasst. README.md, CONTRIBUTING.md, CHANGELOG.md sind ohnehin schon
-- plugin-seitig von Frontmatter ausgenommen. fname ist workspace-relativ, z.B.
-- notes/Foo.md.
local function repos_frontmatter_enabled(fname)
	fname = tostring(fname or "")
	return fname:match("^notes[/\\]") ~= nil or fname:match("^daily[/\\]") ~= nil
end

-- Workspaces nur fuer real existierende Pfade bauen. obsidian.nvim wirft beim
-- Setup, wenn die Liste leer ist, das faengt die cond unten ab.
local workspaces = {}

if has_vault then
	table.insert(workspaces, {
		name = "work",
		path = vault,
		-- Workspace-Specs lesen nur path/name/strict/overrides, alles andere
		-- ignoriert das Plugin. Die Vorlagen muessen daher unter overrides stehen,
		-- damit sie ueberhaupt greifen.
		overrides = {
			templates = {
				folder = "Vorlagen",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M",
			},
		},
	})
end

if has_repos then
	table.insert(workspaces, {
		name = "repos",
		path = repos,
		-- Root fest auf ~/github-repos pinnen, unabhaengig von etwaigen .obsidian-
		-- Ordnern einzelner Repos. Backlinks, Links und Suche spannen den ganzen Baum.
		strict = true,
		overrides = {
			-- Neue und per [[Link]] erzeugte Notizen zentral nach ~/github-repos/notes,
			-- nicht in die Zettelkasten-Struktur des work-Vaults.
			notes_subdir = "notes",
			new_notes_location = "notes_subdir",
			note_path_func = function(spec)
				local title = sanitize(spec.title)
				if title == "" then
					title = "note-" .. (spec.id and tostring(spec.id):sub(1, 6) or "")
				end
				return (spec.dir / title):with_suffix(".md", true)
			end,
			-- Daily Notes zentral nach ~/github-repos/daily.
			daily_notes = {
				folder = "daily",
			},
			-- READMEs und Repo-Doku schuetzen: Frontmatter nur unter notes/ und daily/.
			frontmatter = {
				enabled = repos_frontmatter_enabled,
			},
		},
	})
end

return {
	-- gepflegter Community-Fork, Upstream von epwalsh ist archiviert
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	lazy = true,
	ft = "markdown",
	-- laden, sobald einer der beiden Bereiche vorhanden ist; auf Maschinen ohne
	-- beide bleibt das Plugin aus
	cond = function()
		return has_vault or has_repos
	end,
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = workspaces,

		-- globales note_path_func gilt fuer den work-Vault: Routing nach Zettelkasten
		-- bzw. Architektur Decision Record. Der repos-Workspace ueberschreibt es oben.
		note_path_func = function(spec)
			local function has_tag(tags, want)
				for _, t in ipairs(tags or {}) do
					if t == want then return true end
				end
				return false
			end

			local title = sanitize(spec.title)
			if title == "" then
				title = "note-" .. (spec.id and tostring(spec.id):sub(1, 6) or os.date("%H%M%S"))
			end

			if has_tag(spec.tags, "adr") then
				return "Architektur Decision Record/" .. title
			end

			-- Alles andere landet im Zettelkasten.
			return "Zettelkasten/" .. title
		end,

		-- frontmatter.func ersetzt das fruehere top-level note_frontmatter_func, das in
		-- v3.16.4 deprecated ist und bis 4.0 verschwindet. Gilt fuer beide Workspaces,
		-- welche Dateien es trifft, steuert frontmatter.enabled pro Workspace.
		frontmatter = {
			func = function(note)
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
		},
	},

	config = function(_, opts)
		require("obsidian").setup(opts)

		-- obsidian.nvim wechselt den aktiven Workspace NICHT von selbst beim Oeffnen
		-- einer Datei. Es setzt den Workspace nur einmal beim Laden anhand des cwd
		-- und sonst nur per :Obsidian workspace. Damit haengen die Per-Workspace-
		-- Regeln, etwa der README-Schutz im Repo-Bereich oder das Rendering, sonst
		-- am Zufall des cwd. Darum schalten wir beim Betreten eines Markdown-Buffers
		-- selbst um: nur zwischen den eigenen Workspaces, nie in den .obsidian.wiki-
		-- Fallback, und nur bei echtem Wechsel.
		local Workspace = require("obsidian.workspace")
		local oapi = require("obsidian.api")
		local own = { work = true, repos = true }

		local function autoswitch(buf)
			local fname = vim.api.nvim_buf_get_name(buf)
			if fname == "" then return end
			local ws = oapi.find_workspace(fname)
			if not ws or not own[ws.name] then return end
			if Obsidian.workspace and Obsidian.workspace.name == ws.name then return end
			Workspace.set(ws)
		end

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			group = vim.api.nvim_create_augroup("obsidian_ws_autoswitch", { clear = true }),
			pattern = { "*.md", "*.markdown" },
			callback = function(args)
				autoswitch(args.buf)
			end,
		})

		-- Der initiale BufEnter ist beim Lazy-Laden des Plugins eventuell schon
		-- gelaufen, daher den aktuellen Buffer einmal direkt einordnen.
		autoswitch(vim.api.nvim_get_current_buf())

		-- Belt-and-suspenders fuer den work-Vault: updated: beim Speichern bumpen.
		-- Bewusst nur innerhalb des Vaults, damit keine Repo-Datei angefasst wird.
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.md",
			callback = function(args)
				local path = vim.api.nvim_buf_get_name(args.buf)
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
