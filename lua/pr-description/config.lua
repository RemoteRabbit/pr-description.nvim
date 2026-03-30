---@module "pr-description.config"
---@brief [[
--- Configuration for pr-description.nvim.
---@brief ]]

local M = {}

---@class PrDescriptionConfig
---@field jira_base_url? string Base URL for Jira ticket links (e.g., "https://company.atlassian.net/browse")
---@field auto_detect_platform? boolean Auto-detect GitHub vs GitLab from remote URL (default: true)
---@field confirm_large_pr? boolean Prompt when more than `large_pr_threshold` commits (default: true)
---@field large_pr_threshold? number Number of commits before prompting (default: 10)
---@field sections? table<string, string> Override section headers (key = category, value = markdown header)

---@type PrDescriptionConfig
M.defaults = {
  jira_base_url = nil,
  auto_detect_platform = true,
  confirm_large_pr = true,
  large_pr_threshold = 10,
  sections = nil,
}

---@type PrDescriptionConfig
M.options = vim.deepcopy(M.defaults)

---Apply user configuration.
---@param opts? PrDescriptionConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
