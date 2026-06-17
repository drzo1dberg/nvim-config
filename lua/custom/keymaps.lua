local M = {}
local mapopts = { noremap = true, silent = true }

M.open_noinsert_mode = {
	n = {
		["o"] = { "o<Esc>", "Open below (stay normal mode)" },
		["O"] = { "O<Esc>", "Open above (stay normal mode)" },
	},
}

M.delete_no_yankovizja = {
	n = {
		["<leader>dd"] = { '"_dd', "Delete line (no yankovizja)" },
		["<leader>d"] = { '"_d', "Delete op (no yankovizja)" },
		["<leader>D"] = { '"_D', "Delete to EOL (no yankovizja)" },
		["x"] = { '"_x', "Char delete (no yankovizja)" },
	},
	v = {
		["<leader>d"] = { '"_d', "Visual delete (noyankovizja)" },
	},
}

M.duplicate_line = {
	n = {
		["<leader>yy"] = { ":t.<CR>", "Duplicate line below (no yank)" },
	},
}

M.disabled_arrows = {
	n = {
		["<Left>"] = { '<cmd>echo "Use h to move!"<CR>', "Disable ←" },
		["<Right>"] = { '<cmd>echo "Use l to move!"<CR>', "Disable →" },
		["<Up>"] = { '<cmd>echo "Use k to move!"<CR>', "Disable ↑" },
		["<Down>"] = { '<cmd>echo "Use j to move!"<CR>', "Disable ↓" },
	},
}

M.window = {
	n = {
		["<C-h>"] = { "<C-w>h", "Window left" },
		["<C-l>"] = { "<C-w>l", "Window right" },
		["<C-j>"] = { "<C-w>j", "Window down" },
		["<C-k>"] = { "<C-w>k", "Window up" },
	},
}

M.insert_move = {
	i = {
		["<C-b>"] = { "<ESC>^i", "Line start" },
		["<C-e>"] = { "<End>", "Line end" },
		["<C-h>"] = { "<Left>", "Move left" },
		["<C-l>"] = { "<Right>", "Move right" },
		["<C-j>"] = { "<Down>", "Move down" },
		["<C-k>"] = { "<Up>", "Move up" },
	},
}

M.telescope = {
	n = {
		["<leader>ff"] = { "<cmd>Telescope find_files<CR>", "Find file" },
		["<leader>fg"] = { "<cmd>Telescope live_grep<CR>", "Live grep" },
		["<leader>fr"] = { "<cmd>Telescope oldfiles<CR>", "Recent files" },
		["<leader>fb"] = { "<cmd>Telescope buffers<CR>", "Open buffers" },
		["<leader>fp"] = { "<cmd>Telescope project<CR>", "Projects" },
	},
}

M.harpoon = {
	n = {
		["<leader>ha"] = {
			function()
				-- Datei der aktuellen Harpoon-Liste hinzufügen
				require("harpoon"):list():add()
			end,
			"Harpoon add",
		},

		["<leader>hh"] = {
			function()
				-- Schnellmenü ein/aus; harpoon2 braucht die Liste als Argument
				local harpoon = require("harpoon")
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			"Harpoon menu",
		},

		["<leader>h1"] = {
			function()
				require("harpoon"):list():select(1)
			end,
			"Harpoon 1",
		},
		["<leader>h2"] = {
			function()
				require("harpoon"):list():select(2)
			end,
			"Harpoon 2",
		},
		["<leader>h3"] = {
			function()
				require("harpoon"):list():select(3)
			end,
			"Harpoon 3",
		},
		["<leader>h4"] = {
			function()
				require("harpoon"):list():select(4)
			end,
			"Harpoon 4",
		},
		["<leader>hx"] = {
			function()
				require("harpoon"):list():clear()
			end,
			"Harpoon clear",
		},
	},
}

M.cwd = {
	n = {
		["<leader>cv"] = {
			function()
				local vault = vim.env.OBSIDIAN_VAULT or vim.fn.expand("~/bf")
				vim.env.PWD = vault
				vim.fn.chdir(vault)
				vim.notify("cwd: " .. vault)
			end,
			"cwd in den Vault",
		},
		["<leader>cw"] = {
			function()
				local dir = vim.fn.expand("%:p:h")
				vim.env.PWD = dir
				vim.fn.chdir(dir)
				vim.notify("cwd: " .. dir)
			end,
			"cwd ins Verzeichnis der offenen Datei (current work)",
		},
		["<leader>cd"] = {
			function()
				local fb = require("telescope").extensions.file_browser
				local astate = require("telescope.actions.state")
				local tactions = require("telescope.actions")
				fb.file_browser({
					files = true,
					hidden = true,
					respect_gitignore = false,
					prompt_title = "Ordner setzt cwd, Datei oeffnet plus cwd, mit <C-y>",
					attach_mappings = function(prompt_bufnr, map)
						local confirm = function()
							local entry = astate.get_selected_entry()
							local picker = astate.get_current_picker(prompt_bufnr)
							local target = (entry and entry.path) or (picker and picker.finder and picker.finder.path)
							tactions.close(prompt_bufnr)
							if not target then return end
							local isdir = vim.fn.isdirectory(target) == 1
							local dir = isdir and target or vim.fn.fnamemodify(target, ":h")
							vim.env.PWD = dir
							vim.fn.chdir(dir)
							if isdir then
								vim.notify("cwd: " .. dir)
							else
								vim.cmd.edit(vim.fn.fnameescape(target))
								vim.notify("geoeffnet: " .. vim.fn.fnamemodify(target, ":t") .. "  |  cwd: " .. dir)
							end
						end
						map("i", "<C-y>", confirm)
						map("n", "<C-y>", confirm)
						return true
					end,
				})
			end,
			"cwd-Browser: Ordner setzt cwd, Datei oeffnet plus cwd",
		},
	},
}

for _, section in pairs(M) do
	for mode, mappings in pairs(section) do
		for lhs, rhs in pairs(mappings) do
			local cmd, desc, extra = rhs[1], rhs[2], rhs[3]
			local o = vim.tbl_extend("force", mapopts, { desc = desc })
			if extra then
				o = vim.tbl_extend("force", o, extra)
			end
			vim.keymap.set(mode, lhs, cmd, o)
		end
	end
end

return M
