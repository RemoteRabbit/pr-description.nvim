---@module "pr-description"
---@brief [[
--- pr-description.nvim - Generate PR/MR descriptions from git commits.
---
--- A Neovim plugin that generates well-formatted pull request or merge request
--- descriptions by analyzing git commits and file changes. It categorizes commits
--- using conventional commit patterns, links issues and tickets, and produces
--- markdown-formatted output suitable for GitHub PRs or GitLab MRs.
---
--- Usage:
---   require("pr-description").setup({ jira_base_url = "https://company.atlassian.net/browse" })
---   :PRDescription
---   :MRDescription
---@brief ]]

local config = require("pr-description.config")
local git = require("pr-description.git")
local links = require("pr-description.links")
local parser = require("pr-description.parser")
local formatter = require("pr-description.formatter")

local M = {}

---Setup pr-description.nvim with user options.
---@param opts? PrDescriptionConfig
function M.setup(opts)
  config.setup(opts)
end

---@class GenerateOpts
---@field is_gitlab? boolean Whether this is a GitLab MR (default: false, auto-detected from remote)
---@field to_clipboard? boolean Copy result to clipboard (default: false)

---Generate a PR/MR description from the current branch's commits.
---@param opts? GenerateOpts
---@return string|nil description The generated markdown description, or nil on error
---@return string|nil error Error message if generation failed
function M.generate_description(opts)
  opts = opts or {}
  local cfg = config.options

  -- Validate git repository
  local ok, err = git.check_repo()
  if not ok then
    return nil, err
  end

  -- Get current branch
  local branch
  branch, err = git.get_current_branch()
  if not branch then
    return nil, err
  end

  -- Fetch latest remote refs for accurate comparison
  git.fetch_origin()

  -- Detect base branch
  local base_branch
  base_branch, err = git.detect_base_branch()
  if not base_branch then
    return nil, err
  end

  -- Parse remote URL and determine platform
  local remote_url = git.get_remote_url()
  local host, path = links.parse_remote_url(remote_url)
  local repo_url = links.build_repo_url(host, path)
  local is_gitlab = opts.is_gitlab
  if is_gitlab == nil and cfg.auto_detect_platform then
    is_gitlab = links.is_gitlab_host(host)
  end
  is_gitlab = is_gitlab or false

  -- Get commits
  local commit_lines
  commit_lines, err = git.get_commits(base_branch, branch)
  if not commit_lines then
    return nil, err
  end
  if #commit_lines == 0 then
    return nil, "No commits found ahead of " .. base_branch .. ". Make some commits first!"
  end

  -- Confirm if many commits
  if cfg.confirm_large_pr and #commit_lines > cfg.large_pr_threshold then
    print("Found " .. #commit_lines .. " commits - this seems like a lot for a single PR/MR.")
    print("This might include commits from other merged work.")
    local confirm = vim.fn.input("Continue anyway? (y/n): ")
    if confirm:lower() ~= "y" and confirm:lower() ~= "yes" then
      return nil, "Cancelled"
    end
  end

  -- Create link helper function
  local function process_links(subject, hash)
    if hash then
      return links.make_commit_link(hash, repo_url, is_gitlab)
    end
    return links.add_all_links(subject, repo_url, is_gitlab, cfg.jira_base_url)
  end

  -- Parse commits into categories
  local categories = parser.parse_commits(commit_lines, process_links)

  -- Get file statistics
  local file_changes = git.get_file_changes(base_branch, branch)
  local file_stats_output = git.get_file_stats(base_branch, branch)
  local numstat_lines = git.get_file_numstat(base_branch, branch)

  -- Parse file data
  local file_stats = parser.parse_file_numstat(numstat_lines)
  local file_list = parser.parse_file_changes(file_changes)
  local total_files, total_insertions, total_deletions = parser.parse_total_stats(file_stats_output)

  -- Group files
  local file_groups = formatter.group_files(file_list, file_stats)

  -- Generate final description
  local description = formatter.generate(categories, file_groups, file_stats, {
    total_files = total_files,
    total_insertions = total_insertions,
    total_deletions = total_deletions,
    total_commits = #commit_lines,
    branch = branch,
    base_branch = base_branch,
  })

  if opts.to_clipboard then
    vim.fn.setreg("+", description)
    vim.notify("PR description copied to clipboard!", vim.log.levels.INFO)
  end

  return description
end

return M
