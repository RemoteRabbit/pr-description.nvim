if vim.g.loaded_pr_description then
  return
end
vim.g.loaded_pr_description = true

---@param cmd_opts table
---@param generate_opts GenerateOpts
local function run_description(cmd_opts, generate_opts)
  local pr = require("pr-description")
  if cmd_opts.bang then
    generate_opts.to_clipboard = true
  end
  local description, err = pr.generate_description(generate_opts)
  if err then
    local cmd_name = generate_opts.is_gitlab and "MRDescription" or "PRDescription"
    vim.notify(cmd_name .. ": " .. err, vim.log.levels.ERROR)
    return
  end
  if description then
    vim.cmd("new")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(description, "\n"))
  end
end

vim.api.nvim_create_user_command("PRDescription", function(cmd_opts)
  run_description(cmd_opts, {})
end, {
  desc = "Generate a GitHub PR description",
  bang = true,
})

vim.api.nvim_create_user_command("MRDescription", function(cmd_opts)
  run_description(cmd_opts, { is_gitlab = true })
end, {
  desc = "Generate a GitLab MR description",
  bang = true,
})
