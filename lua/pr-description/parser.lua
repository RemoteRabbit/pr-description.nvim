---@module "pr-description.parser"
---@brief [[
--- Conventional commit parsing and categorization.
---
--- Parses git commits following the conventional commit specification and
--- categorizes them into groups (features, fixes, docs, etc.). Also handles
--- parsing of git diff statistics for file change analysis.
---@brief ]]

local M = {}

---@type {category: string, patterns: string[]}[]
---Patterns for categorizing conventional commits. Each entry maps regex patterns
---to a category name. Patterns match the start of commit subjects.
---
--- Categories and when to use them:
---   features  — New functionality or capabilities (feat:, feature:)
---   fixes     — Bug fixes and corrections (fix:, bugfix:)
---   perf      — Performance improvements without changing behavior (perf:)
---   docs      — Documentation-only changes (doc:, docs:)
---   refactor  — Code restructuring without changing behavior (refactor:)
---   tests     — Adding or updating tests (test:, tests:)
---   style     — Formatting, whitespace, or cosmetic changes (style:, format:)
---   chores    — Maintenance and miscellaneous non-code tasks (chore:)
---   ops       — Operational changes: infrastructure, deployment, CI/CD, monitoring (ops:, ci:, build:)
---   reverts   — Reverting a previous commit (revert:)
---   wip       — Work-in-progress, not ready for review (wip:)
---   breaking  — (derived) Commits with BREAKING CHANGE or ! marker
---   others    — (fallback) Commits not matching any conventional prefix
local COMMIT_PATTERNS = {
  { category = "features", patterns = { "^feat[!%(:]", "^feature[!%(:]" } },
  { category = "fixes", patterns = { "^fix[!%(:]", "^bugfix[!%(:]" } },
  { category = "perf", patterns = { "^perf[!%(:]" } },
  { category = "docs", patterns = { "^docs?[!%(:]" } },
  { category = "refactor", patterns = { "^refactor[!%(:]" } },
  { category = "tests", patterns = { "^test[!%(:]", "^tests[!%(:]" } },
  { category = "style", patterns = { "^style[!%(:]", "^format[!%(:]" } },
  { category = "chores", patterns = { "^chore[!%(:]" } },
  { category = "ops", patterns = { "^ops[!%(:]", "^ci[!%(:]", "^build[!%(:]" } },
  { category = "reverts", patterns = { "^revert[!%(:]" } },
  { category = "wip", patterns = { "^wip[!%(:]" } },
}

---Categorize a commit subject based on conventional commit prefixes.
---@param subject string The commit subject line
---@return string category The category name (e.g., "features", "fixes", "others")
function M.categorize_commit(subject)
  for _, def in ipairs(COMMIT_PATTERNS) do
    for _, pattern in ipairs(def.patterns) do
      if subject:match(pattern) then
        return def.category
      end
    end
  end
  return "others"
end

---Check if a commit subject indicates a breaking change.
---Detects "BREAKING CHANGE" text or "!" marker in conventional commits.
---@param subject string The commit subject line
---@return boolean is_breaking True if this is a breaking change
function M.is_breaking_change(subject)
  return subject:match("BREAKING CHANGE") or subject:match("^%w+!:") or subject:match("^%w+%b()!:")
end

---Parse a single commit line into hash and subject.
---@param line string A line from `git log --oneline` output
---@return string hash The commit hash
---@return string subject The commit subject message
function M.parse_commit_line(line)
  local hash = line:match("^(%S+)")
  local subject = line:match("^%S+%s+(.*)") or line:gsub("^%S+%s*", "")
  return hash, subject
end

---@class CommitCategories
---@field features string[] New functionality or capabilities
---@field fixes string[] Bug fixes and corrections
---@field perf string[] Performance improvements without changing behavior
---@field docs string[] Documentation-only changes
---@field refactor string[] Code restructuring without changing behavior
---@field tests string[] Adding or updating tests
---@field style string[] Formatting, whitespace, or cosmetic changes
---@field chores string[] Maintenance and miscellaneous non-code tasks
---@field ops string[] Operational changes: infrastructure, deployment, CI/CD, monitoring
---@field reverts string[] Commits that revert a previous change
---@field wip string[] Work-in-progress, not ready for review
---@field breaking string[] Commits with BREAKING CHANGE text or ! marker (derived from other categories)
---@field others string[] Commits not matching any conventional commit prefix

---Parse and categorize a list of commit lines.
---@param commit_lines string[] Lines from `git log --oneline` output
---@param link_fn? fun(subject: string, hash?: string): string Optional function to add links
---@return CommitCategories categories Commits grouped by category
function M.parse_commits(commit_lines, link_fn)
  local categories = {
    features = {},
    fixes = {},
    perf = {},
    docs = {},
    refactor = {},
    tests = {},
    style = {},
    chores = {},
    ops = {},
    reverts = {},
    wip = {},
    breaking = {},
    others = {},
  }

  for _, line in ipairs(commit_lines) do
    local hash, subject = M.parse_commit_line(line)
    if subject then
      local processed_subject = link_fn and link_fn(subject) or subject
      local commit_link = link_fn and link_fn(nil, hash) or ""
      local entry = "- " .. processed_subject .. (commit_link or "")

      local category = M.categorize_commit(subject)
      table.insert(categories[category], entry)

      if M.is_breaking_change(subject) then
        table.insert(categories.breaking, entry)
      end
    end
  end

  return categories
end

---@class FileStats
---@field insertions number Number of lines added
---@field deletions number Number of lines deleted

---Parse `git diff --numstat` output into file statistics.
---@param lines string[] Lines from `git diff --numstat` output
---@return table<string, FileStats> stats Map of filepath to insertion/deletion counts
function M.parse_file_numstat(lines)
  local stats = {}
  for _, line in ipairs(lines) do
    local cols = vim.split(line, "\t", { plain = true })
    if #cols >= 3 then
      local insertions_str, deletions_str = cols[1], cols[2]
      local filepath = cols[3]:match(".*=> (.+)") or cols[3]
      stats[filepath] = {
        insertions = insertions_str == "-" and 0 or tonumber(insertions_str) or 0,
        deletions = deletions_str == "-" and 0 or tonumber(deletions_str) or 0,
      }
    end
  end
  return stats
end

---@class FileChange
---@field status string Single-letter status (A=added, M=modified, D=deleted, R=renamed)
---@field path string The file path

---Parse `git diff --name-status` output into file changes.
---@param lines string[] Lines from `git diff --name-status` output
---@return FileChange[] files List of file changes with status and path
function M.parse_file_changes(lines)
  local files = {}
  for _, change in ipairs(lines) do
    local cols = vim.split(change, "\t", { plain = true })
    local status_token = cols[1] or ""
    local status = status_token:sub(1, 1)
    local filepath = cols[#cols] or ""

    if filepath ~= "" then
      table.insert(files, { status = status, path = filepath })
    end
  end
  return files
end

---Parse total statistics from `git diff --stat` output.
---Extracts the summary line (e.g., "5 files changed, 100 insertions(+), 20 deletions(-)").
---@param file_stats_output string The full `git diff --stat` output
---@return number total_files Number of files changed
---@return number total_insertions Total lines inserted
---@return number total_deletions Total lines deleted
function M.parse_total_stats(file_stats_output)
  local total_files, total_insertions, total_deletions = 0, 0, 0

  if not file_stats_output or file_stats_output == "" then
    return total_files, total_insertions, total_deletions
  end

  local lines = vim.split(file_stats_output, "\n")
  for i = #lines, 1, -1 do
    local line = lines[i]:match("^%s*(.-)%s*$")
    if line and line ~= "" and line:match("files? changed") then
      total_files = tonumber(line:match("(%d+) files? changed")) or 0
      total_insertions = tonumber(line:match("(%d+) insertions?%(?%+?%)?")) or 0
      total_deletions = tonumber(line:match("(%d+) deletions?%(?%-?%)?")) or 0
      break
    end
  end

  return total_files, total_insertions, total_deletions
end

return M
