-- What: snacks.nvim supplies the dashboard, file explorer, pickers, terminal, and other editor tools.
-- How: It loads at startup; the mappings below open its tools and toggle editor features.
-- Why: Related navigation and interface tools share a consistent set of windows and controls.

-- Remember the explorer's hide-all toggle separately for each root directory.
local hide_all = {}

-- The dashboard uses image.nvim to draw this local image above its menu.
local dashboard_image = vim.fn.expand("~/Pictures/neovim-dashboard-image.png")
local dashboard_image_id = "snacks_dashboard_image"
local dashboard_image_handle = nil
local dashboard_image_state = nil
local dashboard_image_autocmds_are_set = false

-- Clear the rendered image while keeping the position needed to draw it again.
local function clear_dashboard_image()
	if dashboard_image_handle ~= nil then
		pcall(function()
			dashboard_image_handle:clear()
		end)

		dashboard_image_handle = nil
	end

	local ok, image = pcall(require, "image")

	if ok then
		pcall(function()
			image.clear(dashboard_image_id)
		end)
	end
end

local function can_show_dashboard_image()
	local has_image = vim.fn.filereadable(dashboard_image) == 1

	return has_image
end

-- Forget the saved position when the dashboard closes so later events cannot redraw it.
local function close_dashboard_image()
	dashboard_image_state = nil
	clear_dashboard_image()
end

local function draw_dashboard_image()
	if dashboard_image_state == nil then
		return
	end

	if not can_show_dashboard_image() then
		clear_dashboard_image()
		return
	end

	if not vim.api.nvim_win_is_valid(dashboard_image_state.win) then
		clear_dashboard_image()
		return
	end

	if not vim.api.nvim_buf_is_valid(dashboard_image_state.buf) then
		clear_dashboard_image()
		return
	end

	-- A valid window may now display another buffer, where the dashboard image does not belong.
	if vim.api.nvim_win_get_buf(dashboard_image_state.win) ~= dashboard_image_state.buf then
		clear_dashboard_image()
		return
	end

	local ok, image = pcall(require, "image")

	if not ok then
		return
	end

	clear_dashboard_image()

	dashboard_image_handle = image.from_file(dashboard_image, {
		id = dashboard_image_id,
		window = dashboard_image_state.win,
		buffer = dashboard_image_state.buf,
		x = dashboard_image_state.x,
		y = dashboard_image_state.y,
		width = 60,
		height = 16,
	})

	if dashboard_image_handle == nil then
		return
	end

	dashboard_image_handle:render()
end

local function schedule_draw_dashboard_image()
	vim.schedule(draw_dashboard_image)
end

local function schedule_delayed_draw_dashboard_image()
	-- Allow tab and window changes to settle before placing the image again.
	vim.defer_fn(draw_dashboard_image, 100)
end

local function setup_dashboard_image_autocmds()
	if dashboard_image_autocmds_are_set then
		return
	end

	dashboard_image_autocmds_are_set = true

	local group = vim.api.nvim_create_augroup("dashboard_image", {
		clear = true,
	})

	-- Clear terminal graphics when Neovim loses focus, exits, or is suspended.
	vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre", "VimSuspend" }, {
		group = group,
		callback = clear_dashboard_image,
	})

	vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
		group = group,
		callback = schedule_draw_dashboard_image,
	})

	-- Remove the image while windows are rearranged, then redraw after closing or switching tabs.
	vim.api.nvim_create_autocmd("WinNew", {
		group = group,
		callback = clear_dashboard_image,
	})

	vim.api.nvim_create_autocmd({ "WinClosed", "TabEnter" }, {
		group = group,
		callback = schedule_delayed_draw_dashboard_image,
	})
end

local function render_dashboard_image(dashboard, position)
	dashboard_image_state = {
		win = dashboard.win,
		buf = dashboard.buf,
		x = position[2],
		-- image.nvim counts rows from zero, while the dashboard supplies a one-based row.
		y = position[1] - 1,
	}

	dashboard.on("UpdatePre", clear_dashboard_image, dashboard.augroup)
	dashboard.on("Closed", close_dashboard_image, dashboard.augroup)
	setup_dashboard_image_autocmds()
	schedule_draw_dashboard_image()
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		dashboard = {
			enabled = true,
			width = 60,
			sections = {
				{
					render = render_dashboard_image,
					enabled = can_show_dashboard_image,
					height = 16,
					text = ("\n"):rep(15),
					-- Keep image.nvim's placeholder rows above the first menu option.
					padding = 1,
				},
				{ section = "keys", gap = 1, padding = 0 },
				{ text = "\n", padding = 0 },
				{ section = "startup" },
			},
		},
		explorer = { enabled = true },
		-- Snacks image support is also used by ipynb.nvim for notebook output.
		image = { enabled = true },
		indent = {
			enabled = true,
			indent = {
				char = "▏",
			},
			scope = {
				char = "▏",
			},
		},
		input = { enabled = true },

		lazygit = {
			win = {
				position = "float",
				relative = "editor",
				width = 0,
				height = 0,
				row = 0,
				col = 0,
				border = "none",
				backdrop = false,
			},
		},

		notifier = {
			enabled = true,
			timeout = 3000,
		},

		-- Share hidden-file controls across pickers and add explorer-specific actions.
		picker = {
			enabled = true,
			win = {
				input = {
					keys = {
						["<a-h>"] = false,
						["<a-i>"] = false,

						["H"] = { "toggle_hidden", mode = { "n", "i" } },
						["I"] = { "toggle_ignored", mode = { "n", "i" } },
					},
				},

				list = {
					keys = {
						["<a-h>"] = false,
						["<a-i>"] = false,

						["H"] = "toggle_hidden",
						["I"] = "toggle_ignored",
					},
				},
			},
			sources = {
				explorer = {
					actions = {
						terminal_here = function(picker)
							Snacks.terminal(nil, {
								cwd = picker:dir(),
							})
						end,

						toggle_item_hidden = function(picker, item)
							if not item or not item.file then
								return
							end

							local tree = require("snacks.explorer.tree")
							local node = tree:node(item.file)

							if not node then
								return
							end

							node.hidden = not node.hidden

							picker:refresh()
						end,

						toggle_all_hidden = function(picker)
							local tree = require("snacks.explorer.tree")
							local cwd = picker:cwd()
							local root = tree:node(cwd)

							if not root then
								return
							end

							hide_all[cwd] = not hide_all[cwd]

							-- When restoring visibility, keep dotfiles hidden as they were by default.
							for _, node in pairs(root.children) do
								if hide_all[cwd] then
									node.hidden = true
								else
									node.hidden = node.name:sub(1, 1) == "."
								end
							end

							picker:refresh()
						end,
					},

					win = {
						list = {
							keys = {
								["<c-/>"] = "terminal_here",
								["<c-_>"] = "terminal_here",

								["zh"] = "toggle_item_hidden",
								["zH"] = "toggle_all_hidden",
							},
						},
					},
				},
			},
		},
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = false },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		styles = {
			notification = {
				-- Wrap long notifications so their full text remains visible.
				wo = { wrap = true },
			},
		},

		zen = {
			toggles = {
				dim = false,
			},
			win = {
				backdrop = {
					transparent = false,
					blend = 90,
				},
			},
		},
		terminal = {
			win = {
				style = "minimal",
				position = "bottom",

				wo = {
					winhighlight = "Normal:Normal,NormalNC:Normal",
				},

				on_win = function(self)
					-- Keep the terminal's top edge free of the regular window bar.
					vim.wo[self.win].winbar = ""
				end,
			},
		},
	},

	keys = {
		-- Open the main navigation tools and file explorer.
		{
			"<leader><space>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>,",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>n",
			function()
				Snacks.picker.notifications()
			end,
			desc = "Notification History",
		},
		{
			"<leader>e",
			function()
				local explorers = Snacks.picker.get({ source = "explorer" })
				local explorer = explorers[1]

				-- Reuse an existing explorer rather than opening another one.
				if explorer then
					explorer:focus("list")
				else
					Snacks.explorer()
				end
			end,
			desc = "Focus/Open Explorer",
		},
		{
			"<leader>E",
			function()
				for _, explorer in ipairs(Snacks.picker.get({ source = "explorer" })) do
					explorer:close()
				end
			end,
			desc = "Close Explorer",
		},
		-- Find files, buffers, and projects.
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find Config File",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.git_files()
			end,
			desc = "Find Git Files",
		},
		{
			"<leader>fp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent",
		},
		-- Browse Git branches, history, and changes.
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Git Branches",
		},
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git Log",
		},
		{
			"<leader>gL",
			function()
				Snacks.picker.git_log_line()
			end,
			desc = "Git Log Line",
		},
		{
			"<leader>gs",
			function()
				Snacks.picker.git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>gS",
			function()
				Snacks.picker.git_stash()
			end,
			desc = "Git Stash",
		},
		{
			"<leader>gd",
			function()
				Snacks.picker.git_diff()
			end,
			desc = "Git Diff (Hunks)",
		},
		{
			"<leader>gf",
			function()
				Snacks.picker.git_log_file()
			end,
			desc = "Git Log File",
		},
		-- Browse GitHub issues and pull requests.
		{
			"<leader>gi",
			function()
				Snacks.picker.gh_issue()
			end,
			desc = "GitHub Issues (open)",
		},
		{
			"<leader>gI",
			function()
				Snacks.picker.gh_issue({ state = "all" })
			end,
			desc = "GitHub Issues (all)",
		},
		{
			"<leader>gp",
			function()
				Snacks.picker.gh_pr()
			end,
			desc = "GitHub Pull Requests (open)",
		},
		{
			"<leader>gP",
			function()
				Snacks.picker.gh_pr({ state = "all" })
			end,
			desc = "GitHub Pull Requests (all)",
		},
		-- Search text in buffers or project files.
		{
			"<leader>sb",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer Lines",
		},
		{
			"<leader>sB",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep Open Buffers",
		},
		{
			"<leader>sg",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Search Word. Visual selection or word",
			mode = { "n", "x" },
		},
		-- Search editor information such as commands, diagnostics, and help.
		{
			'<leader>s"',
			function()
				Snacks.picker.registers()
			end,
			desc = "Registers",
		},
		{
			"<leader>s/",
			function()
				Snacks.picker.search_history()
			end,
			desc = "Search History",
		},
		{
			"<leader>sa",
			function()
				Snacks.picker.autocmds()
			end,
			desc = "Autocmds",
		},
		{
			"<leader>sb",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer Lines",
		},
		{
			"<leader>sc",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>sC",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>sD",
			function()
				Snacks.picker.diagnostics_buffer()
			end,
			desc = "Buffer Diagnostics",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>sH",
			function()
				Snacks.picker.highlights()
			end,
			desc = "Highlights",
		},
		{
			"<leader>si",
			function()
				Snacks.picker.icons()
			end,
			desc = "Icons",
		},
		{
			"<leader>sj",
			function()
				Snacks.picker.jumps()
			end,
			desc = "Jumps",
		},
		{
			"<leader>sk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<leader>sl",
			function()
				Snacks.picker.loclist()
			end,
			desc = "Location List",
		},
		{
			"<leader>sm",
			function()
				Snacks.picker.marks()
			end,
			desc = "Marks",
		},
		{
			"<leader>sM",
			function()
				Snacks.picker.man()
			end,
			desc = "Man Pages",
		},
		{
			"<leader>sp",
			function()
				Snacks.picker.lazy()
			end,
			desc = "Search for Plugin Spec",
		},
		{
			"<leader>sq",
			function()
				local quickfix

				Snacks.picker.qflist({
					finder = function(opts, ctx)
						quickfix = vim.fn.getqflist({ id = 0, changedtick = 0, items = 0 })
						local items = require("snacks.picker.source.qf").qf(opts, ctx)
						local index = 1

						-- Keep original positions, including when identical entries appear more than once.
						for _, item in ipairs(items) do
							while index <= #quickfix.items do
								local matches = vim.deep_equal(item.item, quickfix.items[index])
								if matches then
									item.quickfix_index = index
								end
								index = index + 1
								if matches then
									break
								end
							end
						end

						return items
					end,
					actions = {
						remove_quickfix = function(picker)
							local selected = picker:selected({ fallback = true })
							if #selected == 0 then
								return
							end

							local current = vim.fn.getqflist({ id = 0, changedtick = 0 })
							if current.id ~= quickfix.id or current.changedtick ~= quickfix.changedtick then
								vim.notify("Quickfix list changed; refreshed without removing entries.")
								picker:refresh()
								return
							end

							local remove = {}
							for _, item in ipairs(selected) do
								if item.quickfix_index then
									remove[item.quickfix_index] = true
								end
							end

							local remaining = {}
							for index, item in ipairs(quickfix.items) do
								if not remove[index] then
									table.insert(remaining, item)
								end
							end

							vim.fn.setqflist({}, "r", { id = quickfix.id, items = remaining })
							picker:refresh()
						end,
					},
					win = {
						input = {
							keys = {
								["dd"] = { "remove_quickfix", mode = "n" },
							},
						},
						list = {
							keys = {
								["dd"] = { "remove_quickfix", mode = "n" },
							},
						},
					},
				})
			end,
			desc = "Quickfix List",
		},
		{
			"<leader>sR",
			function()
				Snacks.picker.resume()
			end,
			desc = "Resume",
		},
		{
			"<leader>su",
			function()
				Snacks.picker.undo()
			end,
			desc = "Undo History",
		},
		{
			"<leader>uC",
			function()
				Snacks.picker.colorschemes()
			end,
			desc = "Colorschemes",
		},
		-- Use LSP results to navigate code and find symbols.
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_declarations()
			end,
			desc = "Goto Declaration",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
		},
		{
			"gai",
			function()
				Snacks.picker.lsp_incoming_calls()
			end,
			desc = "C[a]lls Incoming",
		},
		{
			"gao",
			function()
				Snacks.picker.lsp_outgoing_calls()
			end,
			desc = "C[a]lls Outgoing",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>sS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "LSP Workspace Symbols",
		},
		-- Open utility windows and control the editing layout.
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>n",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>bd",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>gg",
			function()
				-- Leave Zen mode before opening the full-editor Lazygit window.
				if Snacks.zen.win then
					Snacks.zen()
				end
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"<c-/>",
			function()
				local cwd = vim.fn.expand("%:p:h")
				if cwd == "" then
					cwd = vim.fn.getcwd()
				end

				Snacks.terminal(nil, { cwd = cwd })
			end,
			desc = "Toggle Terminal",
		},
		{
			"<c-_>",
			-- Some terminals send Ctrl-_ for Ctrl-/, so both keys open the same terminal.
			function()
				local cwd = vim.fn.expand("%:p:h")
				if cwd == "" then
					cwd = vim.fn.getcwd()
				end

				Snacks.terminal(nil, { cwd = cwd })
			end,
			desc = "which_key_ignore",
		},
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},
		{
			"<leader>N",
			desc = "Neovim News",
			function()
				Snacks.win({
					file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
					width = 0.6,
					height = 0.6,
					wo = {
						spell = false,
						wrap = false,
						signcolumn = "yes",
						statuscolumn = " ",
						conceallevel = 3,
					},
				})
			end,
		},
		{
			"<leader>ld",
			function()
				Snacks.terminal.toggle("lazydocker", {
					win = {
						position = "float",
						relative = "editor",
						width = 0,
						height = 0,
						row = 0,
						col = 0,
						border = "none",
						backdrop = false,
					},
				})
			end,
			desc = "Lazydocker",
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Expose inspection helpers after startup for debugging this configuration.
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end

				-- Use Snacks to display values printed by the := command.
				if vim.fn.has("nvim-0.11") == 1 then
					vim._print = function(_, ...)
						dd(...)
					end
				else
					vim.print = _G.dd
				end

				-- Provide shortcuts for changing common editor options during a session.
				Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
				Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
				Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
				Snacks.toggle.diagnostics():map("<leader>ud")
				Snacks.toggle.line_number():map("<leader>ul")
				Snacks.toggle
					.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
					:map("<leader>uc")
				Snacks.toggle.treesitter():map("<leader>uT")
				Snacks.toggle
					.option("background", { off = "light", on = "dark", name = "Dark Background" })
					:map("<leader>ub")
				Snacks.toggle.inlay_hints():map("<leader>uh")
				Snacks.toggle.indent():map("<leader>ug")
				Snacks.toggle.dim():map("<leader>uD")
			end,
		})
	end,
}
