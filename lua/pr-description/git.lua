---@module "pr-description.git"
---@brief [[
--- Git operations for PR description generation.
---
--- Provides functions for interacting with git to extract repository information,
--- branch details, commit history, and file change statistics.
---@brief ]]

local M = {}

---Check if current directory is inside a git repository.
---@return boolean|nil ok True if in a git repository, nil on error
---@return string|nil error Error message if not in a repository
function M.check_repo()
  vim.fn.system("git rev-parse --git-dir")
  if vim.v.shell_error ~= 0 then
    return nil, "Not in a git repository"
  end
  return true
end

---Get the name of the current git branch.
---@return string|nil branch The current branch name
---@return string|nil error Error message if branch could not be determined
function M.get_current_branch()
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  if vim.v.shell_error ~= 0 or branch == "" then
    return nil, "Could not determine current branch (detached HEAD?)"
  end
  return branch
end

---Detect the base branch to compare against.
---Tries origin/HEAD first, then falls back to origin/main, origin/master,
---and finally local main/master branches.
---@return string|nil base_branch The detected base branch (e.g., "origin/main")
---@return string|nil error Error message if no base branch could be detected
function M.detect_base_branch()
  -- Try origin/HEAD (configured default branch)
  local origin_head =
    vim.fn.system("git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error == 0 and origin_head ~= "" then
    return origin_head
  end

  -- Fallback: check remote tracking branches
  vim.fn.system("git show-ref --verify --quiet refs/remotes/origin/main")
  if vim.v.shell_error == 0 then
    return "origin/main"
  end

  vim.fn.system("git show-ref --verify --quiet refs/remotes/origin/master")
  if vim.v.shell_error == 0 then
    return "origin/master"
  end

  -- Fallback: check local branches
  vim.fn.system("git show-ref --verify --quiet refs/heads/main")
  if vim.v.shell_error == 0 then
    return "main"
  end

  vim.fn.system("git show-ref --verify --quiet refs/heads/master")
  if vim.v.shell_error == 0 then
    return "master"
  end

  return nil, "Could not detect base branch (no main/master found locally or on origin)"
end

---Get the remote origin URL.
---@return string url The remote origin URL (may be empty if not configured)
---@return integer count Number of replacements made (from gsub)
function M.get_remote_url()
  return vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
end

---Fetch latest refs from origin to ensure accurate comparisons.
---@return boolean ok True if fetch succeeded or was skipped gracefully
function M.fetch_origin()
  vim.fn.system({ "git", "fetch", "origin", "--quiet" })
  return vim.v.shell_error == 0
end

---Find the merge-base (fork point) between two branches.
---@param base_branch string The base branch
---@param branch string The current branch
---@return string|nil merge_base The merge-base commit hash, or nil on error
---@return string|nil error Error message if merge-base failed
function M.get_merge_base(base_branch, branch)
  local result = vim.fn.system({ "git", "merge-base", base_branch, branch }):gsub("\n", "")
  if vim.v.shell_error ~= 0 or result == "" then
    return nil, "Failed to find merge-base between " .. base_branch .. " and " .. branch
  end
  return result
end

---Get commit messages between base branch and current branch.
---Uses merge-base to only include commits unique to the current branch.
---@param base_branch string The base branch to compare from
---@param branch string The current branch to compare to
---@return string[]|nil commits List of commit lines (hash + subject), or nil on error
---@return string|nil error Error message if git log failed
function M.get_commits(base_branch, branch)
  local merge_base, mb_err = M.get_merge_base(base_branch, branch)
  if not merge_base then
    return nil, mb_err
  end
  local commits = vim.fn.systemlist({
    "git",
    "log",
    "--oneline",
    "--no-merges",
    merge_base .. ".." .. branch,
  })
  if vim.v.shell_error ~= 0 then
    return nil, "Failed to get commits: git log failed"
  end
  return commits
end

---Get file change status (added, modified, deleted) between branches.
---Uses merge-base for accurate comparison.
---@param base_branch string The base branch to compare from
---@param branch string The current branch to compare to
---@return string[] changes List of file changes in "status\tfilepath" format
function M.get_file_changes(base_branch, branch)
  local merge_base = M.get_merge_base(base_branch, branch)
  local base = merge_base or base_branch
  return vim.fn.systemlist({
    "git",
    "diff",
    "--name-status",
    base .. ".." .. branch,
  })
end

---Get human-readable file statistics (insertions/deletions summary).
---Uses merge-base for accurate comparison.
---@param base_branch string The base branch to compare from
---@param branch string The current branch to compare to
---@return string stats The git diff --stat output as a single string
function M.get_file_stats(base_branch, branch)
  local merge_base = M.get_merge_base(base_branch, branch)
  local base = merge_base or base_branch
  return vim.fn.system({
    "git",
    "diff",
    "--stat",
    base .. ".." .. branch,
  })
end

---Get machine-readable file statistics (insertions/deletions per file).
---Uses merge-base for accurate comparison.
---@param base_branch string The base branch to compare from
---@param branch string The current branch to compare to
---@return string[] numstat List of lines in "insertions\tdeletions\tfilepath" format
function M.get_file_numstat(base_branch, branch)
  local merge_base = M.get_merge_base(base_branch, branch)
  local base = merge_base or base_branch
  return vim.fn.systemlist({
    "git",
    "diff",
    "--numstat",
    base .. ".." .. branch,
  })
end

return M
