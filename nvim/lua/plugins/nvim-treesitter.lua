-- What: nvim-treesitter installs parsers that understand the structure of source files.
-- How: The parsers below are installed, and highlighting starts for their filetypes.
-- Why: Syntax-aware highlighting and shared parsers support features such as text objects and tests.

return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",

	config = function()
		local treesitter = require("nvim-treesitter")

		treesitter.install({
			"lua",
			"vim",
			"vimdoc",
			"query",
			"c",
			"python",
			"odin",
			"rust",
			"toml",
			"hcl",
		})

		-- Terraform configuration and variable files both use HCL syntax.
		vim.treesitter.language.register("hcl", { "terraform", "terraform-vars" })

		-- Installing a parser does not start highlighting; enable it when a matching file opens.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"c",
				"python",
				"odin",
				"rust",
				"toml",
				"hcl",
				"terraform",
				"terraform-vars",
			},
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
