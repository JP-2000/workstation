-- What: conform.nvim formats buffers using filetype-specific tools.
-- How: It formats on save or with <leader>F, with LSP formatting as a fallback.
-- Why: The same formatting rules apply to both manual formatting and saves.

return {
	{
		"stevearc/conform.nvim",

		event = { "BufWritePre" },
		cmd = { "ConformInfo" },

		keys = {
			{
				"<leader>F",
				function()
					require("conform").format({ async = true })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},

		opts = {
			formatters_by_ft = {
				python = { "ruff_format" },
				lua = { "stylua" },
				markdown = { "mdformat" },
				rust = { "rustfmt" },
				terraform = { "tofu_fmt" },
				["terraform-vars"] = { "tofu_fmt" },
			},

			formatters = {
				rustfmt = {
					command = vim.fs.joinpath(vim.env.CARGO_HOME or vim.fn.expand("~/.cargo"), "bin", "rustfmt"),
					-- Let rustup select the toolchain for this file.
					cwd = function(_, ctx)
						return ctx.dirname
					end,
				},
				mdformat = {
					-- Resolve .mdformat.toml from the file's directory when formatting stdin.
					cwd = function(_, ctx)
						return ctx.dirname
					end,
				},
			},

			default_format_opts = {
				lsp_format = "fallback",
			},

			format_on_save = {
				-- Limit how long formatting can delay a save.
				timeout_ms = 500,
			},
		},
	},
}
