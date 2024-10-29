local lspconfig = require("lspconfig")
local lsp_zero = require("lsp-zero")
local rustaceanvim = require("rustaceanvim")
local utils = require("valera.utils")
local actions = require("telescope.actions")

--TODO!!!: remove all breakpoints

vim.diagnostic.config({
	virtual_text = false,
	-- if line has say both a .HINT and .WARNING, the "worst" will be shown (as a sign on the left)
	severity_sort = true,
})

function ToggleDiagnostics()
	local state = vim.diagnostic.is_enabled()
	if state then
		vim.diagnostic.enable(false)
	else
		vim.diagnostic.enable(true)
	end
end

function ToggleVirtualText()
	local config = vim.diagnostic.config
	local virtual_text = config().virtual_text

	if virtual_text then
		config({ virtual_text = false })
	else
		config({ virtual_text = true })
	end
end

-- -- Open popup or jump to next problem
local floatOpts = {
	format = function(diagnostic)
		return vim.split(diagnostic.message, "\n")[1]
	end,
	-- source = true,
	-- prefix = "",
	-- suffix = "",
	focusable = true,
	--focusable = false,
	header = ""
}
function JumpToDiagnostic(direction, requestSeverity)
	pcall(function()
		local bufnr = vim.api.nvim_get_current_buf()
		local diagnostics = vim.diagnostic.get(bufnr)
		if #diagnostics == 0 then
			Echo("no diagnostics in 0", "Comment")
		end
		local line = vim.fn.line(".") - 1
		-- severity is [1:4], the lower the "worse"
		local allSeverity = { 1, 2, 3, 4 }
		local targetSeverity = allSeverity
		for _, d in pairs(diagnostics) do
			if d.lnum == line and not BoolPopupOpen() then -- meaning we selected casually
				vim.diagnostic.open_float(floatOpts)
				return
			end
			-- navigate exclusively between errors, if there are any
			if d.severity == 1 and requestSeverity ~= 'all' then
				targetSeverity = { 1 }
			end
		end

		local go_action = direction == 1 and "goto_next" or "goto_prev"
		local get_action = direction == 1 and "get_next" or "get_prev"
		if targetSeverity ~= allSeverity then
			vim.diagnostic[go_action]({ float = floatOpts, severity = targetSeverity })
			return
		else
			-- jump over all on current line
			local nextOnAnotherLine = false
			while not nextOnAnotherLine do
				local d = vim.diagnostic[get_action]({ severity = allSeverity })
				-- this piece of shit is waiting until the end of the function before execution for some reason
				vim.api.nvim_win_set_cursor(0, { d.lnum + 1, d.col })
				if d.lnum ~= line then
					nextOnAnotherLine = true
					break
				end
				if #diagnostics == 1 then
					return
				end
			end
			-- if not, nvim_win_set_cursor will execute after it.
			vim.defer_fn(function() vim.diagnostic.open_float(floatOpts) end, 1)
			return
		end
	end)
end

function YankDiagnosticPopup()
	local popups = GetPopups()
	if #popups == 1 then
		local popup_id = popups[1]
		local bufnr = vim.api.nvim_win_get_buf(popup_id)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local content = table.concat(lines, "\n")
		vim.fn.setreg('+', content)
	else
		return
	end
end

--


--TODO!: add {zz, zt} after some search commands (just appending to the cmd string doesn't work)
local on_attach = function(client, bufnr)
	local telescope_builtin = require("telescope.builtin")

	local function buf_set_keymap(mode, lhs, rhs, opts)
		opts = opts or {}
		opts.buffer = bufnr
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	buf_set_keymap('n', 'K', vim.lsp.buf.hover, { desc = "Hover Info" })
	buf_set_keymap('n', 'gd', vim.lsp.buf.definition, { desc = "Go to Definition" })
	buf_set_keymap('n', '<space>lR', vim.lsp.buf.rename, { desc = "Rename" })
	buf_set_keymap('n', '<space>lh', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
		{ desc = "Toggle Inlay Hints" })

	buf_set_keymap('n', '<C-r>', function() JumpToDiagnostic(1, 'max') end, { desc = "Next Error" })
	buf_set_keymap('n', '<C-n>', function() JumpToDiagnostic(-1, 'max') end, { desc = "Previous Error" })
	buf_set_keymap('n', '<C-A-r>', function() JumpToDiagnostic(1, 'all') end, { desc = "Next Diagnostic" })
	buf_set_keymap('n', '<C-A-n>', function() JumpToDiagnostic(-1, 'all') end, { desc = "Previous Diagnostic" })

	buf_set_keymap('n', '<space>lD', vim.lsp.buf.declaration, { desc = "Declaration" })
	buf_set_keymap('n', '<space>lt', vim.lsp.buf.type_definition, { desc = "Type Definition" })
	buf_set_keymap('n', '<space>li', '<cmd>Telescope lsp_implementations<CR>', { desc = "Implementations" })
	buf_set_keymap('n', '<space>lr', '<cmd>Telescope lsp_references<CR>', { desc = "References" })
	buf_set_keymap('n', '<space>ld', function() telescope_builtin.diagnostics({ sort_by = "severity" }) end,
		{ desc = "Diagnostics" })
	buf_set_keymap('n', '<space>ll', function() telescope_builtin.diagnostics({ bufnr = 0, sort_by = "severity" }) end,
		{ desc = "Local Diagnostics" })

	-- -- Search Symbols
	--? should I make the base keymap for this shorter?
	local set_dynamic_symbols_keymap = function(key, symbols)
		local keymap = string.format('<space>l<space>%s', key)
		local desc = string.format("Dynamic Workspace Symbols: [%s]", symbols)

		local opts = {}
		opts.buffer = bufnr
		opts.desc = desc
		opts.silent = true -- doesn't work, telescope still warns when no searches were shown given query
		vim.keymap.set('n', keymap, function() telescope_builtin.lsp_dynamic_workspace_symbols({ symbols = symbols }) end,
			opts)
	end
	--REF:
	-- dynamic_workspace_symbols: matches on [name] only
	-- workspace_symbols: matches on all of [destination, name, type]
	buf_set_keymap('n', '<space>lw', '<cmd>Telescope lsp_document_symbols<CR>', { desc = "Document Symbols" })
	buf_set_keymap('n', '<space>lW', function() telescope_builtin.lsp_dynamic_workspace_symbols() end,
		{ desc = "Dynamic Workspace Symbols" })
	buf_set_keymap('n', '<space>l<space>a',
		function() telescope_builtin.lsp_workspace_symbols() end,
		{ desc = "Workspace Symbols" })
	set_dynamic_symbols_keymap('f', { "function" })
	set_dynamic_symbols_keymap('s', { "struct" })
	set_dynamic_symbols_keymap('m', { "module" })
	set_dynamic_symbols_keymap('c', { "constant" })
	set_dynamic_symbols_keymap('e', { "enum" })
	set_dynamic_symbols_keymap('v', { "variable" })
	--

	buf_set_keymap('n', '<space>lz', '<cmd>Telescope lsp_incoming_calls<CR>', { desc = "Incoming Calls" })
	buf_set_keymap('n', '<space>lZ', '<cmd>Telescope lsp_outgoing_calls<CR>', { desc = "Outgoing Calls" })
	buf_set_keymap('n', '<space>lf', function() vim.lsp.buf.format({ async = true }) end, { desc = "Format" })
	buf_set_keymap({ 'n', 'v' }, '<space>la', vim.lsp.buf.code_action, { desc = "Code Action" })
	buf_set_keymap('n', '<space>ly', YankDiagnosticPopup, { desc = "Yank Diagnostic Popup" })
	buf_set_keymap('n', '<space>ls', ToggleDiagnostics, { desc = "Toggle Diagnostics" })
	buf_set_keymap('n', '<space>lv', ToggleVirtualText, { desc = "Toggle Virtual Text" })
	buf_set_keymap('n', '<space>l2',
		'<cmd>lua vim.opt.shiftwidth=2<CR><cmd>lua vim.opt.tabstop=2<CR><cmd>lua vim.opt.expandtab=true<CR>',
		{ desc = "Tab = 2" })
	buf_set_keymap('n', '<space>l4',
		'<cmd>lua vim.opt.shiftwidth=4<CR><cmd>lua vim.opt.tabstop=4<CR><cmd>lua vim.opt.expandtab=true<CR>',
		{ desc = "Tab = 4" })
	buf_set_keymap('n', '<space>l8',
		'<cmd>lua vim.opt.shiftwidth=8<CR><cmd>lua vim.opt.tabstop=8<CR><cmd>lua vim.opt.expandtab=true<CR>',
		{ desc = "Tab = 8" })
	buf_set_keymap('n', '<space>l0',
		'<cmd>lua vim.opt.expandtab=false<CR><cmd>lua vim.opt.tabstop=2<CR><cmd>lua vim.opt.shiftwidth=2<CR><cmd>lua vim.opt.softtabstop=0<CR>',
		{ desc = "Reset Tab Settings" })


	if client.supports_method('textDocument/formatting') then
		require('lsp-format').on_attach(client)
	end

	vim.bo.tabstop = 2
	vim.bo.softtabstop = 0
	vim.bo.shiftwidth = 2
	vim.bo.expandtab = false
end


lsp_zero.on_attach(on_attach)


-- Language setup //? Do I still need this? Maybe it's possible to get rid of `lsp_zero` altogether
local lspconfig_servers = { 'ruff_lsp', 'typst_lsp', 'lua_ls', 'gopls', 'bashls', 'clangd', 'jedi_language_server',
	'jsonls', 'marksman', 'nil_ls' }
lsp_zero.setup_servers(lspconfig_servers)
lsp_zero.setup()

vim.g.rust_recommended_style = false


local lua_opts = lsp_zero.nvim_lua_ls()
lspconfig.lua_ls.setup(lua_opts)
--lspconfig.htmx.setup {
--	on_attach = on_attach,
--}
lspconfig.leanls.setup {
	on_attach = on_attach,
}

local function codelldb_adapter()
	local extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.10.0/'
	local codelldb_path = extension_path .. 'adapter/codelldb'
	local liblldb_path = extension_path .. 'lldb/lib/liblldb'
	local this_os = vim.uv.os_uname().sysname;

	if this_os:find "Windows" then
		codelldb_path = extension_path .. "adapter\\codelldb.exe"
		liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
	else
		-- The liblldb extension is .so for Linux and .dylib for MacOS
		liblldb_path = liblldb_path .. (this_os == "Linux" and ".so" or ".dylib")
	end

	local cfg = require('rustaceanvim.config')
	return cfg.get_codelldb_adapter(codelldb_path, liblldb_path)
end

vim.g.rustaceanvim = {
	tools = {
		-- Plugin configuration
		--TODO
		--test_executor = 'backround',
	},
	dap = {
		adapter = codelldb_adapter(),
	},
	server = {
		status_notify_level = rustaceanvim.disable, -- doesn't work
		cmd = function()
			local mason_registry = require('mason-registry')
			local ra_binary = mason_registry.is_installed('rust-analyzer')
					and mason_registry.get_package('rust-analyzer'):get_install_path() .. "/rust-analyzer"
					or "rust-analyzer"
			return { ra_binary } -- You can add args to the list, such as '--log-file'
		end,
		on_attach = on_attach,
		default_settings = {
			['rust-analyzer'] = {
				dap = {
					autoload_configuration = true,
				},
				cmd = {
					"rustup", "run", "nightly", "rust-analyzer",
				},
				rustfmt = {
					overrideCommand = { "rustfmt" },
				},
				cargo = {
					BuildScripts = {
						enable = true,
					},
					runBuildScripts = true,
					loadOutDirsFromCheck = true,
					--allFeatures = true, -- will break on projects with incompatible features. If comes up, write a script to copy code before uploading to crates.io and sed `features = ["full"]` for `[]`
					--extraEnv = { CARGO_TARGET_DIR = "target/analyzer" },
				},
				procMacro = {
					enable = true,
				},
				workspace = {
					symbol = {
						search = {
							-- default is "only_types"
							kind = "all_symbols",
						},
					},
				},
				checkOnSave = {
					enable = true,
					--TODO!!: think how to toggle clippy::all (for pedantic checks right before commiting to master)
					command = "clippy",
				},
			},
			--server = {
			--	extraEnv = { CARGO_TARGET_DIR = "target/analyzer" },
			--},
		},
	},
}

lspconfig.gopls.setup({
	on_attach = lsp_zero.default_setup,
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
})

-- Apparently ruff-lsp doesn't provide goto-definition functionality, and is meant to be used in tandem
lspconfig.jedi_language_server.setup({
	on_attach = lsp_zero.default_setup,
	settings = {
		jedi_language_server = {
			diagnostics = {
				enable = false,
			},
			hover = {
				enable = true,
			},
			--TODO!!!!!!!!!: disable `reportRedeclaration`
			jediSettings = {
				autoImportModules = {},
				caseInsensitiveCompletion = true,
				debug = false,
			},
		},
	},
})

lspconfig.ruff_lsp.setup({
	on_attach = lsp_zero.default_setup,
	cmd = { 'ruff-lsp' },
	filetypes = { 'python' },
	root_dir = lspconfig.util.find_git_ancestor,
})

lspconfig.typst_lsp.setup({
	on_attach = lsp_zero.default_setup,
	settings = {
		exportPdf = "onType",
	},
})

lspconfig.nil_ls.setup({
	on_attach = lsp_zero.default_setup,
	settings = {
		formatter = { command = { "nixpkgs-fmt" } },
	},
})