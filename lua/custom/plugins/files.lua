return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = vim.fn.executable("make") == 1,
			},
		},
		opts = function(_, opts)
			opts.defaults = vim.tbl_extend("force", opts.defaults or {}, {
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
			})
			require("telescope").load_extension("fzf")
		end,
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"stevearc/oil.nvim",
		opts = {},
	},
}
