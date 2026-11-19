-- What: render-markdown.nvim renders Markdown directly in the editing buffer.
-- How: Rendering starts automatically; use <leader>p to toggle it for the current buffer.
-- Why: Read formatted Markdown without opening a browser or a separate preview.

return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = "markdown",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.icons",
	},
	opts = {},
	keys = {
		{
			"<leader>p",
			"<cmd>RenderMarkdown buf_toggle<cr>",
			ft = "markdown",
			mode = "n",
			desc = "Toggle Markdown rendering",
		},
	},
}
