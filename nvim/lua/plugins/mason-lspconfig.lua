-- What: mason-lspconfig.nvim connects Mason-managed language servers to Neovim's LSP.
-- How: The lists below install the servers and command-line tools used by this config.
-- Why: Keeping those tools in one place makes the language setup easier to maintain.

-- These server names belong to nvim-lspconfig; Mason handles their installation.
local lsp_servers = {
	"pyright",
	"texlab",
	"ols",
	"terraformls",
}

-- mason-tool-installer manages the separate formatters, linters, and debugging tools.
local mason_tools = {
	"ruff",
	"stylua",
	"mdformat",
	"debugpy",
	"latexindent",
	"vale",
}

return {
	"mason-org/mason-lspconfig.nvim",

	opts = {
		ensure_installed = lsp_servers,
	},

	config = function(_, opts)
		-- Use the installed OpenTofu CLI instead of looking for Terraform.
		vim.lsp.config("terraformls", {
			init_options = {
				terraform = {
					path = "tofu",
				},
			},
		})

		-- Limit Python diagnostics to open files and use basic type checking.
		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						autoImportCompletions = true,
						diagnosticMode = "openFilesOnly",
						typeCheckingMode = "basic",
					},
				},
			},
		})

		require("mason-lspconfig").setup(opts)

		require("mason-tool-installer").setup({
			ensure_installed = mason_tools,
		})
	end,

	dependencies = {
		-- Mason manages tool installations, and nvim-lspconfig supplies server definitions.
		{ "mason-org/mason.nvim", opts = {} },
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"neovim/nvim-lspconfig",
	},
}
