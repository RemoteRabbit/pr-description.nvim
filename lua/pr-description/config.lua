---@module "pr-description.config"
---@brief [[
--- Configuration for pr-description.nvim.
---@brief ]]

local M = {}

---@class PrDescriptionConfig
---@field auto_detect_platform? boolean Auto-detect GitHub vs GitLab from remote URL (default: true)
---@field autofold? boolean Auto-fold a file change group when it has many files (default: true)
---@field autofold_threshold? number Number of files in a group before it auto-folds (default: 10)
---@field confirm_large_pr? boolean Prompt when more than `large_pr_threshold` commits (default: true)
---@field enable_icons? boolean Include icons in final PR/MR pr-description (default: true)
---@field enable_plugin_credit? boolean Include a credit link to pr-description.nvim in the footer (default: true)
---@field enable_stats_footer? boolean Include stats footer in final PR/MR pr-description (default: true)
---@field fetch_before_generate? boolean Fetch origin before generating to ensure accurate comparison (default: true)
---@field foldable_file_changes? boolean Wrap each file change group in a collapsible <details> block (default: false)
---@field jira_base_url? string Base URL for Jira ticket links (e.g., "https://company.atlassian.net/browse")
---@field large_pr_threshold? number Number of commits before prompting (default: 10)
---@field sections? table<string, string> Override section headers (key = category, value = markdown header)
---@field strip_commit_prefix? boolean Strip conventional commit prefix/scope from output (default: true)

---@type PrDescriptionConfig
M.defaults = {
  auto_detect_platform = true,
  autofold = true,
  autofold_threshold = 10,
  confirm_large_pr = true,
  enable_icons = true,
  enable_plugin_credit = true,
  enable_stats_footer = true,
  fetch_before_generate = true,
  foldable_file_changes = false,
  jira_base_url = nil,
  large_pr_threshold = 10,
  sections = nil,
  strip_commit_prefix = true,
}

---@type PrDescriptionConfig
M.options = vim.deepcopy(M.defaults)

---Apply user configuration.
---@param opts? PrDescriptionConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
