local function notify(msg, level, id)
	local TIMEOUT = 5000
	Snacks.notify(msg, { timeout = TIMEOUT, title = "git", level = level, id = id })
end

local function notify_result(cmd_str, code, output, id)
	local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
	local status = code == 0 and " succeeded" or " failed"
	local sep = code == 0 and ": " or ":\n"
	notify(cmd_str .. status .. (output ~= "" and sep .. output or ""), level, id)
end

local function get_git_subcommands()
	local result = vim.system({ "git", "help", "-a" }, { text = true }):wait()
	local commands = {}
	for line in (result.stdout or ""):gmatch("[^\n]+") do
		local cmd = line:match("^%s+(%a[%a-]+)%s")
		if cmd then table.insert(commands, cmd) end
	end
	return commands
end

local function git_commit()
	local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
	if git_dir == "" then return notify("Not a git repository", vim.log.levels.ERROR) end
	local msg_file = vim.fn.fnamemodify(git_dir, ":p") .. "COMMIT_EDITMSG"

	local result = vim.system({ "git", "status", "--short" }, { text = true }):wait()
	local staged = {}
	for line in (result.stdout or ""):gmatch("[^\n]+") do
		if line:match("^[MADRC]") then table.insert(staged, "# " .. line) end
	end
	if #staged == 0 then return notify("Nothing to commit", vim.log.levels.WARN) end

	local template = { "" }
	vim.list_extend(template, staged)
	table.insert(template, "#")
	result = vim.system({ "git", "diff", "--cached", "--stat" }, { text = true }):wait()
	if result.code == 0 and result.stdout ~= "" then
		for line in result.stdout:gmatch("[^\n]+") do
			table.insert(template, "# " .. line)
		end
	end
	table.insert(template, "# Write to commit, quit to abort")

	vim.fn.writefile(template, msg_file)
	local win = Snacks.win({
		file = msg_file,
		enter = true,
		style = "float",
		bo = { filetype = "gitcommit", bufhidden = "wipe", modifiable = true },
		wo = { cursorline = true },
		keys = { q = "close" },
		on_win = function() vim.cmd.startinsert() end,
	})

	win:on("BufWriteCmd", function()
		local buf = vim.api.nvim_get_current_buf()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local msg = vim.tbl_filter(function(l) return not l:match("^%s*#") and l:match("%S") end, lines)
		if #msg == 0 then return notify("Empty commit message", vim.log.levels.WARN) end
		vim.fn.writefile(msg, msg_file)
		local r = vim.system({ "git", "commit", "-F", msg_file }, { cwd = vim.fn.getcwd() }):wait()
		notify_result("git commit", r.code, r.stdout ~= "" and r.stdout or r.stderr)
		if r.code == 0 then
			vim.bo[buf].modified = false
			win:close()
		end
	end)
end

local function run_git_command(args)
	if args[1] == "commit" and not vim.tbl_contains(args, "-m") and not vim.tbl_contains(args, "--message") then
		return git_commit()
	end

	local cmd_tbl = { "git", unpack(args) }
	local cmd_str = table.concat(cmd_tbl, " ")
	notify(cmd_str .. "...", nil, cmd_str)

	local background_commands = {
		push = true,
		pull = true,
		fetch = true,
		clone = true,
		remote = true,
	}

	local is_background = background_commands[args[1]]
	if type(is_background) == "function" then is_background = is_background(args) end

	if is_background then
		vim.system(cmd_tbl, { cwd = vim.fn.getcwd() }, function(result)
			vim.schedule(
				function()
					notify_result(cmd_str, result.code, result.stdout ~= "" and result.stdout or result.stderr, cmd_str)
				end
			)
		end)
		return
	end

	local terminal = Snacks.terminal.open(cmd_tbl, {
		interactive = true,
		auto_close = false,
		win = { style = "float" },
	})

	vim.api.nvim_create_autocmd("TermClose", {
		buffer = terminal.buf,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(terminal.buf, 0, -1, false)
			while #lines > 0 and lines[#lines]:match("^%s*$") do
				table.remove(lines)
			end

			local exit_code = vim.v.event.status

			if #lines <= 1 then
				terminal:close()
				notify_result(cmd_str, exit_code, lines[1] or "", cmd_str)
			else
				vim.keymap.set("t", "<cr>", function() terminal:close() end, { buffer = terminal.buf })
				if exit_code ~= 0 then
					notify(cmd_str .. " failed (press Enter to close)", vim.log.levels.WARN, cmd_str)
				end
			end
		end,
	})
end

vim.api.nvim_create_user_command(
	"Git",
	function(opts) run_git_command(vim.split(opts.args, " ", { trimempty = true })) end,
	{
		nargs = "+",
		desc = "Run git command asynchronously",
		complete = function(arglead, cmdline)
			local args = vim.split(cmdline, " ", { trimempty = true })
			if #args == 1 or (#args == 2 and cmdline:match(" %S+$")) then
				return vim.tbl_filter(function(s) return s:find("^" .. arglead) ~= nil end, get_git_subcommands())
			end
			return vim.fn.getcompletion(arglead, "file")
		end,
	}
)

vim.api.nvim_create_user_command("Gread", function(opts)
	local file = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
	local result = vim.system({ "git", "show", "HEAD:" .. vim.fn.fnamemodify(file, ":.") }, { text = true }):wait()
	if result.code ~= 0 then return notify("Gread failed:\n" .. result.stderr, vim.log.levels.ERROR) end
	local lines = vim.split(result.stdout, "\n", { plain = true })
	if lines[#lines] == "" then table.remove(lines) end
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, { nargs = "?", desc = "Replace buffer with git HEAD version of file" })

vim.api.nvim_create_user_command("Gwrite", function(opts)
	local file = opts.args ~= "" and opts.args or vim.fn.expand("%:p")
	run_git_command({ "add", file })
end, { nargs = "?", desc = "Stage current file" })
