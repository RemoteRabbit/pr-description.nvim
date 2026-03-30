---@module "pr-description.links"
---@brief [[
--- URL parsing and link generation for PR descriptions.
---
--- Handles parsing of git remote URLs (SSH and HTTPS formats), building
--- repository URLs, and generating markdown links for issues, Jira tickets,
--- and commit references.
---@brief ]]

local M = {}

---Parse a git remote URL into host and path components.
---Supports SSH (git@host:path or ssh://git@host/path) and HTTPS formats.
---@param url string The git remote URL
---@return string|nil host The hostname (e.g., "github.com")
---@return string|nil path The repository path (e.g., "owner/repo")
function M.parse_remote_url(url)
  local host, path
  -- SSH format: git@host:path.git or ssh://git@host/path.git
  host, path = url:match("git@([^:]+):(.+)")
  if not host then
    host, path = url:match("ssh://[^@]+@([^/]+)/(.+)")
  end
  -- HTTPS format: https://host/path.git
  if not host then
    host, path = url:match("https?://([^/]+)/(.+)")
  end
  if path then
    path = path:gsub("%.git$", "")
  end
  return host, path
end

---Build a full HTTPS repository URL from host and path.
---@param host string|nil The hostname (e.g., "github.com")
---@param path string|nil The repository path (e.g., "owner/repo")
---@return string url The full repository URL, or empty string if host/path is nil
function M.build_repo_url(host, path)
  if host and path then
    return "https://" .. host .. "/" .. path
  end
  return ""
end

---Check if a host is a GitLab instance.
---@param host string|nil The hostname to check
---@return boolean is_gitlab True if the host contains "gitlab"
function M.is_gitlab_host(host)
  return host and host:match("gitlab") ~= nil
end

---Add markdown links to issue references (e.g., "fixes #123").
---Converts patterns like "fixes #123" to "fixes [#123](repo_url/issues/123)".
---@param text string The text to process
---@param repo_url string The repository base URL
---@param is_gitlab boolean Whether to use GitLab URL format (/-/issues/)
---@return string text The text with issue references converted to links
function M.add_issue_links(text, repo_url, is_gitlab)
  if repo_url == "" then
    return text
  end

  local issue_path = is_gitlab and "/-/issues/" or "/issues/"

  text = text:gsub("(fixes?) #(%d+)", "%1 [#%2](" .. repo_url .. issue_path .. "%2)")
  text = text:gsub("(closes?) #(%d+)", "%1 [#%2](" .. repo_url .. issue_path .. "%2)")
  text = text:gsub("(resolves?) #(%d+)", "%1 [#%2](" .. repo_url .. issue_path .. "%2)")

  return text
end

---Add markdown links to Jira ticket references (e.g., "PROJ-123").
---@param text string The text to process
---@param base_url? string Jira base URL (e.g., "https://company.atlassian.net/browse")
---@return string text The text with Jira tickets converted to links
function M.add_jira_links(text, base_url)
  if not base_url then
    return text
  end
  return text:gsub("([A-Z][A-Z0-9]*%-[0-9]+)", function(ticket)
    return "[" .. ticket .. "](" .. base_url .. "/" .. ticket .. ")"
  end)
end

---Add all supported markdown links (issues and Jira tickets).
---@param text string The text to process
---@param repo_url string The repository base URL
---@param is_gitlab boolean Whether to use GitLab URL format
---@param jira_base_url? string Jira base URL for ticket links
---@return string text The text with all references converted to links
function M.add_all_links(text, repo_url, is_gitlab, jira_base_url)
  text = M.add_issue_links(text, repo_url, is_gitlab)
  text = M.add_jira_links(text, jira_base_url)
  return text
end

---Create a markdown link to a commit.
---@param hash string The commit hash (short or full)
---@param repo_url string The repository base URL
---@param is_gitlab boolean Whether to use GitLab URL format (/-/commit/)
---@return string link The markdown link, or empty string if repo_url is empty
function M.make_commit_link(hash, repo_url, is_gitlab)
  if repo_url == "" then
    return ""
  end

  local commit_path = is_gitlab and "/-/commit/" or "/commit/"
  return " [[" .. hash .. "]](" .. repo_url .. commit_path .. hash .. ")"
end

return M
