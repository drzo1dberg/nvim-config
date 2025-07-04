local M = {}
local mapopts = { noremap = true, silent = true }

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
				-- Schnellmenü ein/aus
				require("harpoon").ui:toggle_quick_menu()
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

for _, section in pairs(M) do
	for mode, mappings in pairs(section) do
		for lhs, rhs in pairs(mappings) do
			local cmd, desc = rhs[1], rhs[2]
			vim.keymap.set(mode, lhs, cmd, vim.tbl_extend("force", mapopts, { desc = desc }))
		end
	end
end

return M
