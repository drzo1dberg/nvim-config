return {
	"nvim-telescope/telescope-project.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				project = {
					base_dirs = {
						{ "~/github-repos/workrepos", max_depth = 1 },
						{ "~/github-repos/drzo1dberg", max_depth = 1 },
					},
				},
			},
		})
		telescope.load_extension("project")
	end,
}
