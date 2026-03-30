---@module "pr-description.formatter"
---@brief [[
--- Markdown generation for PR descriptions.
---
--- Formats categorized commits and file changes into a well-structured
--- markdown document suitable for GitHub PRs or GitLab MRs. Includes
--- emoji indicators, collapsible sections, and statistics.
---@brief ]]

local config = require("pr-description.config")

local M = {}

---@type {key: string, title: string}[]
---Section headers for each commit category with emoji prefixes.
---Order here controls the order sections appear in the generated description.
local CATEGORY_SECTIONS = {
  { key = "breaking", title = "## ⚠️ Breaking Changes" },
  { key = "features", title = "## ✨ Features" },
  { key = "fixes", title = "## 🐛 Bug Fixes" },
  { key = "perf", title = "## ⚡ Performance" },
  { key = "docs", title = "## 📚 Documentation" },
  { key = "refactor", title = "## 🔨 Refactoring" },
  { key = "tests", title = "## 🧪 Tests" },
  { key = "style", title = "## 💄 Style" },
  { key = "chores", title = "## 🔧 Maintenance" },
  { key = "ops", title = "## 🏗️ Operations" },
  { key = "reverts", title = "## ⏪ Reverts" },
  { key = "others", title = "## 📦 Other Changes" },
  { key = "wip", title = "## 🚧 Work in Progress" },
}

local GROUP_RANK = {
  Root = 1,
  Src = 2,
  Lib = 3,
  Api = 4,
  Components = 5,
  Utils = 6,
  Config = 7,
  Tests = 98,
  Documentation = 99,
}

local STATUS_SYMBOLS = {
  A = " ✨",
  M = " 📝",
  D = " 🗑️",
  R = " ↻",
}

---Add the summary placeholder section to the output.
---@param lines string[] The output lines table (modified in place)
function M.add_summary_section(lines)
  table.insert(lines, "## Summary")
  table.insert(lines, "")
  table.insert(lines, "_Brief description of changes_")
  table.insert(lines, "")
end

---Add categorized commit sections to the output.
---Only adds sections for categories that have commits.
---@param lines string[] The output lines table (modified in place)
---@param categories CommitCategories The categorized commits
function M.add_category_sections(lines, categories)
  local custom_sections = config.options.sections

  for _, section in ipairs(CATEGORY_SECTIONS) do
    local items = categories[section.key]
    if items and #items > 0 then
      local title = (custom_sections and custom_sections[section.key]) or section.title
      table.insert(lines, title)
      for _, item in ipairs(items) do
        table.insert(lines, item)
      end
      table.insert(lines, "")
    end
  end
end

---Determine which logical group a file belongs to based on its path.
---Groups files by top-level directory or special patterns (tests, docs, config).
---@param filepath string The file path
---@return string group The group name (e.g., "Root", "Tests", "Documentation")
function M.determine_file_group(filepath)
  if filepath:match("^src/") or filepath:match("^lib/") then
    local parts = vim.split(filepath, "/")
    if #parts > 1 then
      return (parts[2]:gsub("^%l", string.upper))
    end
  elseif filepath:match("^test") or filepath:match("_test%.") or filepath:match("%.test%.") then
    return "Tests"
  elseif filepath:match("^doc") or filepath:match("README") or filepath:match("%.md$") then
    return "Documentation"
  elseif filepath:match("^config") or filepath:match("%.config%.") then
    return "Configuration"
  else
    local dir = filepath:match("^([^/]+)/")
    if dir then
      return dir:gsub("^%l", string.upper)
    end
  end
  return "Root"
end

---@class FileInfo
---@field path string The file path
---@field symbol string Emoji status symbol
---@field stats string Formatted stats string (e.g., " (+10/-5)")

---Group files by their logical directory/category.
---@param file_list FileChange[] List of file changes
---@param file_stats table<string, FileStats> Map of filepath to statistics
---@return table<string, FileInfo[]> groups Files grouped by category name
function M.group_files(file_list, file_stats)
  local groups = {}

  for _, file in ipairs(file_list) do
    local group_name = M.determine_file_group(file.path)

    if not groups[group_name] then
      groups[group_name] = {}
    end

    local symbol = STATUS_SYMBOLS[file.status] or ""
    local stats = file_stats[file.path]
    local stats_str = ""

    if stats then
      if stats.insertions > 0 and stats.deletions > 0 then
        stats_str = string.format(" (+%d/-%d)", stats.insertions, stats.deletions)
      elseif stats.insertions > 0 then
        stats_str = string.format(" (+%d)", stats.insertions)
      elseif stats.deletions > 0 then
        stats_str = string.format(" (-%d)", stats.deletions)
      end
    end

    table.insert(groups[group_name], {
      path = file.path,
      symbol = symbol,
      stats = stats_str,
    })
  end

  return groups
end

---Sort group names by predefined priority (Root first, Tests/Docs last).
---@param groups table<string, FileInfo[]> The groups to sort
---@return string[] sorted_names Group names in sorted order
function M.sort_groups(groups)
  local sorted = {}
  for name, _ in pairs(groups) do
    table.insert(sorted, name)
  end

  table.sort(sorted, function(a, b)
    local rank_a = GROUP_RANK[a] or 50
    local rank_b = GROUP_RANK[b] or 50
    if rank_a ~= rank_b then
      return rank_a < rank_b
    end
    return a < b
  end)

  return sorted
end

---Add the file changes section to the output.
---Lists files grouped by category with statistics.
---@param lines string[] The output lines table (modified in place)
---@param file_groups table<string, FileInfo[]> Files grouped by category
---@param file_stats table<string, FileStats> Map of filepath to statistics
function M.add_file_changes_section(lines, file_groups, file_stats)
  if not next(file_groups) then
    return
  end

  table.insert(lines, "## 📁 File Changes")
  table.insert(lines, "")

  local sorted_groups = M.sort_groups(file_groups)

  for _, group_name in ipairs(sorted_groups) do
    local files = file_groups[group_name]
    if files and #files > 0 then
      local group_insertions, group_deletions = 0, 0

      for _, file_info in ipairs(files) do
        local stats = file_stats[file_info.path]
        if stats then
          group_insertions = group_insertions + stats.insertions
          group_deletions = group_deletions + stats.deletions
        end
      end

      table.insert(lines, string.format("### %s (+%d/-%d lines)", group_name, group_insertions, group_deletions))

      for _, file_info in ipairs(files) do
        table.insert(lines, string.format("- `%s`%s%s", file_info.path, file_info.stats, file_info.symbol))
      end

      table.insert(lines, "")
    end
  end
end

---@class DescriptionStats
---@field total_files number Total number of files changed
---@field total_insertions number Total lines inserted
---@field total_deletions number Total lines deleted
---@field total_commits number Total number of commits
---@field branch string Current branch name
---@field base_branch string Base branch name

---Add the footer section with summary statistics.
---@param lines string[] The output lines table (modified in place)
---@param stats DescriptionStats Summary statistics
function M.add_footer(lines, stats)
  table.insert(lines, "---")
  table.insert(lines, "")
  table.insert(
    lines,
    string.format(
      "**Changes:** %d files, +%d insertions, -%d deletions",
      stats.total_files,
      stats.total_insertions,
      stats.total_deletions
    )
  )
  table.insert(lines, "**Commits:** " .. stats.total_commits)
  table.insert(lines, "**Branch:** `" .. stats.branch .. "`")
  table.insert(lines, "**Base:** `" .. stats.base_branch .. "`")
end

---Generate the complete PR/MR description.
---@param categories CommitCategories Categorized commits
---@param file_groups table<string, FileInfo[]> Files grouped by category
---@param file_stats table<string, FileStats> Map of filepath to statistics
---@param stats DescriptionStats Summary statistics
---@return string description The complete markdown description
function M.generate(categories, file_groups, file_stats, stats)
  local lines = {}

  M.add_summary_section(lines)
  M.add_category_sections(lines, categories)
  M.add_file_changes_section(lines, file_groups, file_stats)
  M.add_footer(lines, stats)

  return table.concat(lines, "\n")
end

return M
