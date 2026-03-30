if vim.g.loaded_pr_description then
  return
end
vim.g.loaded_pr_description = true

vim.api.nvim_create_user_command("PRDescription", function(cmd_opts)
  local pr = require("pr-description")
  local opts = {}
  if cmd_opts.bang then
    opts.to_clipboard = true
  end
  local description, err = pr.generate_description(opts)
  if err then
    vim.notify("PRDescription: " .. err, vim.log.levels.ERROR)
    return
  end
  if description and not opts.to_clipboard then
    vim.cmd("new")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(description, "\n"))
  end
end, {
  desc = "Generate a GitHub PR description",
  bang = true,
})

vim.api.nvim_create_user_command("MRDescription", function(cmd_opts)
  local pr = require("pr-description")
  local opts = { is_gitlab = true }
  if cmd_opts.bang then
    opts.to_clipboard = true
  end
  local description, err = pr.generate_description(opts)
  if err then
    vim.notify("MRDescription: " .. err, vim.log.levels.ERROR)
    return
  end
  if description and not opts.to_clipboard then
    vim.cmd("new")
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(description, "\n"))
  end
end, {
  desc = "Generate a GitLab MR description",
  bang = true,
})
