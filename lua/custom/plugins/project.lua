return {
	"nvim-telescope/telescope-project.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				project = {
					-- alle Repos unter ~/github-repos, egal wie die Unterordner heissen
					base_dirs = {
						{ "~/github-repos", max_depth = 2 },
					},
				},
			},
		})
		telescope.load_extension("project")
	end,
}
