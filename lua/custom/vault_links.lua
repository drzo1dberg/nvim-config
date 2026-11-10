-- Repariert relative Markdown-Links in Notizen, die zk-archive nach archiv/ verschoben hat.
local M = {}

local uv = vim.uv

-- Zerlegt einen absoluten Pfad in Teile und loest "." und ".." auf.
local function split_path(path)
	local parts = {}
	for part in string.gmatch(path, "[^/]+") do
		if part == ".." then
			if #parts > 0 then
				table.remove(parts)
			end
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end
	return parts
end

local function join_path(parts)
	return "/" .. table.concat(parts, "/")
end

local function exists(path)
	return uv.fs_stat(path) ~= nil
end

-- Baut den relativen Pfad von einem Ordner zu einem Ziel, beide absolut.
local function relative_path(from_dir, target)
	local from = split_path(from_dir)
	local to = split_path(target)
	local common = 0
	while common < #from and common < #to and from[common + 1] == to[common + 1] do
		common = common + 1
	end
	local out = {}
	for _ = common + 1, #from do
		table.insert(out, "..")
	end
	for i = common + 1, #to do
		table.insert(out, to[i])
	end
	return table.concat(out, "/")
end

local function url_decode(text)
	local decoded = string.gsub(text, "%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	return decoded
end

-- Liefert true fuer Ziele, die kein relativer Dateipfad sind.
local function is_external(target)
	if string.match(target, "^%a[%w+.-]*:") then
		return true
	end
	local first = string.sub(target, 1, 1)
	return first == "#" or first == "/" or first == "<"
end

-- Vault-Pfad: Argument, sonst erste Zeile von ~/.config/obsidian-vault, sonst ~/bf.
local function resolve_vault(vault)
	if vault and vault ~= "" then
		return vim.fn.expand(vault)
	end
	local override = vim.fn.expand("~/.config/obsidian-vault")
	if vim.fn.filereadable(override) == 1 then
		local first_line = vim.fn.readfile(override)[1]
		if first_line and first_line ~= "" then
			return vim.fn.expand(first_line)
		end
	end
	return vim.fn.expand("~/bf")
end

-- Prueft ein Linkziel und liefert Status und, falls reparierbar, das neue Ziel.
local function check_target(target, note_dir, origin_dir)
	local path = target
	local title = ""
	local path_part, title_part = string.match(target, '^(%S+)(%s+".*")$')
	if path_part then
		path = path_part
		title = title_part
	end

	local anchor = ""
	local hash = string.find(path, "#", 1, true)
	if hash then
		anchor = string.sub(path, hash)
		path = string.sub(path, 1, hash - 1)
	end
	if path == "" then
		return "ok", nil
	end

	local decoded = url_decode(path)
	if exists(join_path(split_path(note_dir .. "/" .. decoded))) then
		return "ok", nil
	end

	local old_target = join_path(split_path(origin_dir .. "/" .. decoded))
	if not exists(old_target) then
		return "broken", nil
	end

	local new_path = relative_path(note_dir, old_target)
	if string.find(path, "%%20") then
		new_path = string.gsub(new_path, " ", "%%20")
	end
	return "fixable", new_path .. anchor .. title
end

-- Prueft alle Links einer Notiz, schreibt sie bei apply zurueck und sammelt Befunde.
local function process_note(file, origin_dir, apply, findings)
	local note_dir = vim.fs.dirname(file)
	local lines = vim.fn.readfile(file, "b")
	local in_fence = false
	local changed = false

	for lnum, line in ipairs(lines) do
		if string.match(line, "^%s*```") or string.match(line, "^%s*~~~") then
			in_fence = not in_fence
		elseif not in_fence then
			local new_line = string.gsub(line, "(%]%()([^)]+)(%))", function(open, target, close)
				if is_external(target) then
					return nil
				end
				local status, new_target = check_target(target, note_dir, origin_dir)
				if status == "ok" then
					return nil
				end
				table.insert(findings, {
					file = file,
					lnum = lnum,
					status = status,
					old = target,
					new = new_target,
				})
				if status == "fixable" then
					return open .. new_target .. close
				end
				return nil
			end)
			if new_line ~= line then
				lines[lnum] = new_line
				changed = true
			end
		end
	end

	if apply and changed then
		vim.fn.writefile(lines, file, "b")
	end
end

-- Durchsucht <vault>/zettelkasten/archiv und liefert die Befunde als Liste.
function M.scan(opts)
	opts = opts or {}
	local vault = resolve_vault(opts.vault)
	local origin_dir = vault .. "/zettelkasten"
	local archive_dir = origin_dir .. "/archiv"
	local findings = {}

	if not exists(archive_dir) then
		return findings, "Archiv-Ordner fehlt: " .. archive_dir
	end

	local files = vim.fs.find(function(name)
		return string.match(name, "%.md$") ~= nil
	end, { path = archive_dir, type = "file", limit = math.huge })
	table.sort(files)

	for _, file in ipairs(files) do
		process_note(file, origin_dir, opts.apply == true, findings)
	end
	return findings, nil
end

local function count_status(findings, status)
	local count = 0
	for _, finding in ipairs(findings) do
		if finding.status == status then
			count = count + 1
		end
	end
	return count
end

local function to_quickfix(findings, apply)
	local items = {}
	for _, finding in ipairs(findings) do
		local text = "kaputt, Ziel nicht gefunden: " .. finding.old
		if finding.status == "fixable" then
			local verb = "reparierbar: "
			if apply then
				verb = "repariert: "
			end
			text = verb .. finding.old .. " -> " .. finding.new
		end
		table.insert(items, { filename = finding.file, lnum = finding.lnum, text = text })
	end
	return items
end

local function run_command(apply)
	local findings, err = M.scan({ apply = apply })
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end
	local fixable = count_status(findings, "fixable")
	local broken = count_status(findings, "broken")
	vim.fn.setqflist({}, " ", { title = "VaultLinks", items = to_quickfix(findings, apply) })
	if apply then
		vim.cmd("checktime")
	end
	local verb = "reparierbar"
	if apply then
		verb = "repariert"
	end
	vim.notify(string.format("VaultLinks: %d %s, %d ohne Ziel", fixable, verb, broken))
	if #findings > 0 then
		vim.cmd("copen")
	end
end

-- Legt :VaultLinksCheck und :VaultLinksFix an.
function M.setup()
	vim.api.nvim_create_user_command("VaultLinksCheck", function()
		run_command(false)
	end, { desc = "Kaputte relative Links im Zettelkasten-Archiv listen" })
	vim.api.nvim_create_user_command("VaultLinksFix", function()
		run_command(true)
	end, { desc = "Relative Links im Zettelkasten-Archiv reparieren" })
end

-- Headless: nvim -u NONE -l vault_links.lua [--apply] [--vault <pfad>]
local function run_cli(args)
	local apply = false
	local vault = nil
	local i = 1
	while i <= #args do
		if args[i] == "--apply" then
			apply = true
		elseif args[i] == "--vault" then
			vault = args[i + 1]
			i = i + 1
		else
			io.stderr:write("Unbekannte Option: " .. args[i] .. "\n")
			return 2
		end
		i = i + 1
	end

	local findings, err = M.scan({ apply = apply, vault = vault })
	if err then
		io.stderr:write(err .. "\n")
		return 1
	end

	local label = "DRY-RUN"
	if apply then
		label = "APPLY"
	end
	for _, finding in ipairs(findings) do
		local where = finding.file .. ":" .. finding.lnum
		if finding.status == "fixable" then
			io.stdout:write(string.format("[%s] %s: %s -> %s\n", label, where, finding.old, finding.new))
		else
			io.stdout:write(string.format("[%s] %s: kein Ziel fuer %s\n", label, where, finding.old))
		end
	end
	local fixable = count_status(findings, "fixable")
	local broken = count_status(findings, "broken")
	io.stdout:write(string.format("[%s] fixable=%d broken=%d\n", label, fixable, broken))
	return 0
end

if arg and arg[0] and string.find(arg[0], "vault_links.lua", 1, true) then
	os.exit(run_cli(arg))
end

return M
