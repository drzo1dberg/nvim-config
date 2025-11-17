-- ~/.config/nvim/lua/obsidian_story/init.lua
local M = {}

-- 0) Random Seed
do
	local seed = tonumber(tostring(os.time()):reverse():sub(1, 9))
	math.randomseed(seed)
end

-- 1) Utils ----------------------------------------------------
local function slugify(str)
	str = (str or ""):lower()
	local map = { ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["ß"] = "ss" }
	str = str:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
		return map[c] or c
	end)
	str = str:gsub("[^%w%s%-_]", ""):gsub("%s+", "-"):gsub("%-+", "-")
	return str
end

local function uuid_v4()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (
		template:gsub("[xy]", function(c)
			local v = (c == "x") and math.random(0, 15) or (math.random(0, 15) % 4 + 8)
			return string.format("%x", v)
		end)
	)
end

local function read_file(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if ok then
		return table.concat(lines, "\n")
	end
	local fh = io.open(path, "r")
	if not fh then
		return nil
	end
	local data = fh:read("*a")
	fh:close()
	return data
end

local function write_file(path, text)
	local ok = pcall(vim.fn.writefile, vim.split(text, "\n", { plain = true }), path)
	if not ok then
		local fh, err = io.open(path, "w")
		if not fh then
			vim.notify("cant write to file: " .. tostring(err), vim.log.levels.ERROR)
			return false
		end
		fh:write(text)
		fh:write("\n")
		fh:close()
	end
	return true
end

local function ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

local function ensure_unique_id_in_frontmatter(text, id)
	id = id or uuid_v4()
	local start1, stop1 = text:find("^%-%-%-\n")
	if not start1 then
		return table.concat({ "---", "id: " .. id, 'created: "' .. os.date("%Y-%m-%d") .. '"', "---", "", text }, "\n")
	end
	local _, stop2 = text:find("\n%-%-%-%s*\n", stop1)
	if not stop2 then
		return table.concat({ "---", "id: " .. id, 'created: "' .. os.date("%Y-%m-%d") .. '"', "---", "", text }, "\n")
	end
	local header = text:sub(1, stop2)
	local body = text:sub(stop2 + 1)
	if header:lower():find("\nid:%s*") then
		header = header:gsub("\n[idI][dD]:%s*.-\n", "\nid: " .. id .. "\n", 1)
	else
		header = header:gsub("^%-%-%-\n", "---\nid: " .. id .. "\n", 1)
	end
	return header .. body
end

local function render_placeholders(s, meta)
	return (
		s:gsub("{{TITLE}}", meta.title or "")
			:gsub("{{SLUG}}", meta.slug or "")
			:gsub("{{DATE}}", meta.date or "")
			:gsub("{{ID}}", meta.id or "")
	)
end

-- 2) Vault & Templates ---------------------------------------
local function vault_root_string()
	local ok, obsidian = pcall(require, "obsidian")
	if not ok then
		return nil, "obsidian.nvim nicht geladen"
	end
	return tostring(obsidian.get_client():vault_root())
end

local function templates_root_string()
	local ok, obsidian = pcall(require, "obsidian")
	if not ok then
		return nil, "obsidian.nvim nicht geladen"
	end
	local client = obsidian.get_client()
	local vault = tostring(client:vault_root())
	local folder = (client.opts and client.opts.templates and client.opts.templates.folder)
	folder = (folder and folder ~= vim.NIL) and tostring(folder) or "templates"
	return vault .. "/" .. folder
end

-- 3) Helpers --------------------------------------------------
local function list_templates(dir)
	local out = {}
	if vim.fn.isdirectory(dir) == 0 then
		return out
	end
	for _, f in ipairs(vim.fn.readdir(dir)) do
		if f:match("%.md$") then
			table.insert(out, f)
		end
	end
	table.sort(out)
	return out
end

local function next_number_in_dir(dir)
	local maxn = 0
	if vim.fn.isdirectory(dir) == 1 then
		for _, f in ipairs(vim.fn.readdir(dir)) do
			local n = tonumber(f:match("^(%d+)_"))
			if n and n > maxn then
				maxn = n
			end
		end
	end
	return tostring(maxn + 1)
end

-- 4) SHORT APIs ----------------------------------------------

-- 4a) Erzeuge komplettes Short-Projekt aus templates/short/*
function M.create_short_project(title)
	local vault, err = vault_root_string()
	if not vault then
		return nil, err
	end
	local tpl_root, err2 = templates_root_string()
	if not tpl_root then
		return nil, err2
	end

	local short_tpl_dir = tpl_root .. "/short"
	if vim.fn.isdirectory(short_tpl_dir) == 0 then
		return nil, "Fehlt: " .. short_tpl_dir .. " (lege dort deine short-Templates an)"
	end

	local slug = slugify(title)
	local date = os.date("%Y-%m-%d")
	local base = vault .. "/shorts/" .. slug
	ensure_dir(base)

	local order_map = {
		short_index = "00_index",
		short_brief = "10_brief",
		short_outline = "20_outline",
		short_cards = "30_cards",
		short_style = "40_style",
		short_draft = "70_draft",
		short_revision = "80_revision",
		short_submission = "90_submission",
	}

	for _, fname in ipairs(vim.fn.readdir(short_tpl_dir)) do
		if fname:match("%.md$") then
			local raw = read_file(short_tpl_dir .. "/" .. fname)
			if raw then
				local meta = { title = title, slug = slug, date = date, id = uuid_v4() }
				local content = ensure_unique_id_in_frontmatter(render_placeholders(raw, meta), meta.id)
				local stem = fname:gsub("%.md$", "")
				local outname = (order_map[stem] or stem) .. ".md"
				local out = base .. "/" .. outname
				if vim.fn.filereadable(out) == 0 then
					write_file(out, content)
				end
			else
				vim.notify("Template nicht lesbar: " .. short_tpl_dir .. "/" .. fname, vim.log.levels.WARN)
			end
		end
	end
	return base .. "/00_index.md"
end

-- 4b) Einzelnes Short-Template instantiieren
-- template_name: z.B. "short_outline.md"
function M.create_short_from_template(template_name, title, target_dir)
	local vault, err = vault_root_string()
	if not vault then
		return nil, err
	end
	local tpl_root, err2 = templates_root_string()
	if not tpl_root then
		return nil, err2
	end
	local short_tpl_dir = tpl_root .. "/short"

	local slug = slugify(title)
	local date = os.date("%Y-%m-%d")
	local id = uuid_v4()

	local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	local dir = target_dir or ((cwd and #cwd > 0 and cwd ~= ".") and cwd or (vault .. "/shorts/" .. slug))
	ensure_dir(dir)

	local src = short_tpl_dir .. "/" .. template_name
	local raw = read_file(src)
	if not raw then
		return nil, "Template nicht lesbar: " .. src
	end

	local content = ensure_unique_id_in_frontmatter(
		render_placeholders(raw, { title = title, slug = slug, date = date, id = id }),
		id
	)

	local stem = template_name:gsub("%.md$", "")
	local map = {
		short_index = "00_index",
		short_brief = "10_brief",
		short_outline = "20_outline",
		short_cards = "30_cards",
		short_style = "40_style",
		short_draft = "70_draft",
		short_revision = "80_revision",
		short_submission = "90_submission",
	}
	local outname = (map[stem] or stem) .. ".md"
	local out = dir .. "/" .. outname
	if write_file(out, content) then
		return out
	end
	return nil, "Konnte Datei nicht schreiben: " .. out
end

-- 4c) Nummerierte Ergänzung in einem Short-Projekt (05_*.md)
-- template_choice: rel. Pfad ab templates/ (optional); wenn nil => leeres Doc
function M.create_short_numbered(number, title, template_choice, target_dir)
	local vault, err = vault_root_string()
	if not vault then
		return nil, err
	end
	local tpl_root = templates_root_string() -- kann nil sein, ist optional
	local slug = slugify(title)
	local date = os.date("%Y-%m-%d")
	local id = uuid_v4()

	local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	local dir = target_dir or ((cwd and #cwd > 0 and cwd ~= ".") and cwd or (vault .. "/shorts/" .. slug))
	ensure_dir(dir)

	local content = ""
	if template_choice and tpl_root then
		local src = tpl_root .. "/" .. template_choice
		local raw = read_file(src)
		if raw then
			content = ensure_unique_id_in_frontmatter(
				render_placeholders(raw, { title = title, slug = slug, date = date, id = id }),
				id
			)
		else
			vim.notify("Template nicht lesbar: " .. src, vim.log.levels.WARN)
		end
	end

	if content == "" then
		content = table.concat({
			"---",
			"id: " .. id,
			'title: "' .. title .. '"',
			'slug: "' .. slug .. '"',
			'created: "' .. date .. '"',
			"tags: [short, note]",
			"---",
			"# " .. tostring(number) .. " " .. title,
			"",
		}, "\n")
	end

	local out_name = string.format("%s_%s.md", tostring(number), slug)
	local out_path = dir .. "/" .. out_name
	if write_file(out_path, content) then
		return out_path
	end
	return nil, "Konnte Datei nicht schreiben: " .. out_path
end

-- 4d) Picker-Liste (nur Short-Templates + optional /single und root)
function M.pick_template_list()
	local tpl_root, err = templates_root_string()
	if not tpl_root then
		return { "LEERES DOKUMENT" }, "templates_root fehlt: " .. tostring(err)
	end
	local list = { "LEERES DOKUMENT" }
	-- bevorzugt short/
	if vim.fn.isdirectory(tpl_root .. "/short") == 1 then
		for _, f in ipairs(list_templates(tpl_root .. "/short")) do
			table.insert(list, "short/" .. f)
		end
	end
	-- optional weitere Templates (falls du mal mischen willst)
	for _, f in ipairs(list_templates(tpl_root)) do
		table.insert(list, f)
	end
	if vim.fn.isdirectory(tpl_root .. "/single") == 1 then
		for _, f in ipairs(list_templates(tpl_root .. "/single")) do
			table.insert(list, "single/" .. f)
		end
	end
	return list
end

function M.suggest_next_number(target_dir)
	return next_number_in_dir(target_dir or (vault_root_string() or ""))
end

-- 5) Commands (für Wrapper) ----------------------------------
M.commands = {}

M.commands.new_short = function()
	local title = vim.fn.input("Short-Titel: ")
	if not title or title == "" then
		return
	end
	local path, err = M.create_short_project(title)
	if not path then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end
	vim.cmd.edit(path)
end

M.commands.new_short_from_template = function()
	local tpl_root = templates_root_string()
	if not tpl_root then
		vim.notify("Templates-Root unbekannt", vim.log.levels.WARN)
		return
	end

	local short_dir = tpl_root .. "/short"
	if vim.fn.isdirectory(short_dir) == 0 then
		vim.notify("Kein short-Template-Ordner: " .. short_dir, vim.log.levels.WARN)
		return
	end

	local list = {}
	for _, f in ipairs(vim.fn.readdir(short_dir)) do
		if f:match("^short_.*%.md$") then
			table.insert(list, f)
		end
	end
	table.sort(list)
	vim.ui.select(list, { prompt = "Short-Template wählen:" }, function(choice)
		if not choice then
			return
		end
		local title = vim.fn.input("Titel (Platzhalter): ")
		if not title or title == "" then
			return
		end
		local path, err = M.create_short_from_template(choice, title)
		if not path then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		vim.cmd.edit(path)
	end)
end

M.commands.new_short_numbered = function()
	local vault = vault_root_string()
	local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	local dir = (cwd and #cwd > 0 and cwd ~= ".") and cwd or (vault .. "/shorts")
	ensure_dir(dir)
	local suggested = next_number_in_dir(dir)

	local number = vim.fn.input("Nummer: ", suggested)
	if not number or number == "" then
		return
	end

	local title = vim.fn.input("Titel: ")
	if not title or title == "" then
		return
	end

	local list = M.pick_template_list()
	vim.ui.select(list, { prompt = "Template (optional):" }, function(choice)
		local tpl = (choice and choice ~= "LEERES DOKUMENT") and choice or nil
		if tpl and not tpl:match("^short/") then
			-- wenn der Picker aus root/single kommt, direkt nutzen
		end
		local path, err = M.create_short_numbered(number, title, tpl, dir)
		if not path then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		vim.cmd.edit(path)
	end)
end

return M
