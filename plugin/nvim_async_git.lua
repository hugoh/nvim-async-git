local function run_git_command(args)
  vim.schedule(function()
    vim.notify("[git] " .. table.concat(args, " ") .. "...", vim.log.levels.INFO)
  end)

  vim.system({ "git", unpack(args) }, {
    cwd = vim.fn.getcwd(),
  }, function(obj)
    vim.schedule(function()
      local cmd = "[git] " .. table.concat(args, " ")
      if obj.code == 0 then
        vim.notify(cmd .. " succeeded", vim.log.levels.INFO)
      else
        local msg = obj.stderr
        vim.notify(cmd .. " failed:\n" .. msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

vim.api.nvim_create_user_command("GitPull", function()
  run_git_command({ "pull" })
end, {})

vim.api.nvim_create_user_command("GitPush", function()
  run_git_command({ "push" })
end, {})

