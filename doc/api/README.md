# API Reference

Auto-generated from LuaCATS annotations.

## pr-description.config

Configuration for pr-description.nvim.

@field enable_icons? boolean Include icons in final PR/MR pr-description (default: true)
@field jira_base_url? string Base URL for Jira ticket links (e.g., "https://company.atlassian.net/browse")
@field large_pr_threshold? number Number of commits before prompting (default: 10)
@field sections? table<string, string> Override section headers (key = category, value = markdown header)
@type PrDescriptionConfig
@type PrDescriptionConfig
Apply user configuration.
@param opts? PrDescriptionConfig

## pr-description.formatter

Markdown generation for PR descriptions.

Formats categorized commits and file changes into a well-structured
markdown document suitable for GitHub PRs or GitLab MRs. Includes
emoji indicators, collapsible sections, and statistics.

Add the summary placeholder section to the output.
@param lines string[] The output lines table (modified in place)
Add categorized commit sections to the output.
Only adds sections for categories that have commits.
@param lines string[] The output lines table (modified in place)
@param categories CommitCategories The categorized commits
Determine which logical group a file belongs to based on its path.
Groups files by top-level directory or special patterns (tests, docs, config).
@param filepath string The file path
@return string group The group name (e.g., "Root", "Tests", "Documentation")
@class FileInfo
@field path string The file path
@field symbol string Emoji status symbol
@field stats string Formatted stats string (e.g., " (+10/-5)")
Group files by their logical directory/category.
@param file_list FileChange[] List of file changes
@param file_stats table<string, FileStats> Map of filepath to statistics
@return table<string, FileInfo[]> groups Files grouped by category name
Sort group names by predefined priority (Root first, Tests/Docs last).
@param groups table<string, FileInfo[]> The groups to sort
@return string[] sorted_names Group names in sorted order
Add the file changes section to the output.
Lists files grouped by category with statistics.
@param lines string[] The output lines table (modified in place)
@param file_groups table<string, FileInfo[]> Files grouped by category
@param file_stats table<string, FileStats> Map of filepath to statistics
@class DescriptionStats
@field total_files number Total number of files changed
@field total_insertions number Total lines inserted
@field total_deletions number Total lines deleted
@field total_commits number Total number of commits
@field branch string Current branch name
@field base_branch string Base branch name
Add the footer section with summary statistics.
@param lines string[] The output lines table (modified in place)
@param stats DescriptionStats Summary statistics
Generate the complete PR/MR description.
@param categories CommitCategories Categorized commits
@param file_groups table<string, FileInfo[]> Files grouped by category
@param file_stats table<string, FileStats> Map of filepath to statistics
@param stats DescriptionStats Summary statistics
@return string description The complete markdown description

## pr-description.git

Git operations for PR description generation.

Provides functions for interacting with git to extract repository information,
branch details, commit history, and file change statistics.

@module "pr-description.git"
@brief [[
Git operations for PR description generation.

Provides functions for interacting with git to extract repository information,
branch details, commit history, and file change statistics.
@brief ]]
Check if current directory is inside a git repository.
@return boolean|nil ok True if in a git repository, nil on error
@return string|nil error Error message if not in a repository
Get the name of the current git branch.
@return string|nil branch The current branch name
@return string|nil error Error message if branch could not be determined
Detect the base branch to compare against.
Tries origin/HEAD first, then falls back to origin/main, origin/master,
and finally local main/master branches.
@return string|nil base_branch The detected base branch (e.g., "origin/main")
@return string|nil error Error message if no base branch could be detected
Get the remote origin URL.
@return string url The remote origin URL (may be empty if not configured)
@return integer count Number of replacements made (from gsub)
Get commit messages between base branch and current branch.
@param base_branch string The base branch to compare from
@param branch string The current branch to compare to
@return string[]|nil commits List of commit lines (hash + subject), or nil on error
@return string|nil error Error message if git log failed
Get file change status (added, modified, deleted) between branches.
@param base_branch string The base branch to compare from
@param branch string The current branch to compare to
@return string[] changes List of file changes in "status\tfilepath" format
Get human-readable file statistics (insertions/deletions summary).
@param base_branch string The base branch to compare from
@param branch string The current branch to compare to
@return string stats The git diff --stat output as a single string
Get machine-readable file statistics (insertions/deletions per file).
@param base_branch string The base branch to compare from
@param branch string The current branch to compare to
@return string[] numstat List of lines in "insertions\tdeletions\tfilepath" format

## pr-description.init

pr-description.nvim - Generate PR/MR descriptions from git commits.

A Neovim plugin that generates well-formatted pull request or merge request
descriptions by analyzing git commits and file changes. It categorizes commits
using conventional commit patterns, links issues and tickets, and produces
markdown-formatted output suitable for GitHub PRs or GitLab MRs.

Usage:
  require("pr-description").setup({ jira_base_url = "https://company.atlassian.net/browse" })
  :PRDescription
  :MRDescription

descriptions by analyzing git commits and file changes. It categorizes commits
using conventional commit patterns, links issues and tickets, and produces
markdown-formatted output suitable for GitHub PRs or GitLab MRs.

Usage:
  require("pr-description").setup({ jira_base_url = "https://company.atlassian.net/browse" })
  :PRDescription
  :MRDescription
@brief ]]
Setup pr-description.nvim with user options.
@param opts? PrDescriptionConfig
@class GenerateOpts
@field is_gitlab? boolean Whether this is a GitLab MR (default: false, auto-detected from remote)
@field to_clipboard? boolean Copy result to clipboard (default: false)
Generate a PR/MR description from the current branch's commits.
@param opts? GenerateOpts
@return string|nil description The generated markdown description, or nil on error
@return string|nil error Error message if generation failed

## pr-description.links

URL parsing and link generation for PR descriptions.

Handles parsing of git remote URLs (SSH and HTTPS formats), building
repository URLs, and generating markdown links for issues, Jira tickets,
and commit references.

@module "pr-description.links"
@brief [[
URL parsing and link generation for PR descriptions.

Handles parsing of git remote URLs (SSH and HTTPS formats), building
repository URLs, and generating markdown links for issues, Jira tickets,
and commit references.
@brief ]]
Parse a git remote URL into host and path components.
Supports SSH (git@host:path or ssh://git@host/path) and HTTPS formats.
@param url string The git remote URL
@return string|nil host The hostname (e.g., "github.com")
@return string|nil path The repository path (e.g., "owner/repo")
Build a full HTTPS repository URL from host and path.
@param host string|nil The hostname (e.g., "github.com")
@param path string|nil The repository path (e.g., "owner/repo")
@return string url The full repository URL, or empty string if host/path is nil
Check if a host is a GitLab instance.
@param host string|nil The hostname to check
@return boolean is_gitlab True if the host contains "gitlab"
Add markdown links to issue references (e.g., "fixes #123").
Converts patterns like "fixes #123" to "fixes [#123](repo_url/issues/123)".
@param text string The text to process
@param repo_url string The repository base URL
@param is_gitlab boolean Whether to use GitLab URL format (/-/issues/)
@return string text The text with issue references converted to links
Add markdown links to Jira ticket references (e.g., "PROJ-123").
@param text string The text to process
@param base_url? string Jira base URL (e.g., "https://company.atlassian.net/browse")
@return string text The text with Jira tickets converted to links
Add all supported markdown links (issues and Jira tickets).
@param text string The text to process
@param repo_url string The repository base URL
@param is_gitlab boolean Whether to use GitLab URL format
@param jira_base_url? string Jira base URL for ticket links
@return string text The text with all references converted to links
Create a markdown link to a commit.
@param hash string The commit hash (short or full)
@param repo_url string The repository base URL
@param is_gitlab boolean Whether to use GitLab URL format (/-/commit/)
@return string link The markdown link, or empty string if repo_url is empty

## pr-description.parser

Conventional commit parsing and categorization.

Parses git commits following the conventional commit specification and
categorizes them into groups (features, fixes, docs, etc.). Also handles
parsing of git diff statistics for file change analysis.

  wip       — Work-in-progress, not ready for review (wip:)
  breaking  — (derived) Commits with BREAKING CHANGE or ! marker
  others    — (fallback) Commits not matching any conventional prefix
Categorize a commit subject based on conventional commit prefixes.
@param subject string The commit subject line
@return string category The category name (e.g., "features", "fixes", "others")
Check if a commit subject indicates a breaking change.
Detects "BREAKING CHANGE" text or "!" marker in conventional commits.
@param subject string The commit subject line
@return boolean is_breaking True if this is a breaking change
Parse a single commit line into hash and subject.
@param line string A line from `git log --oneline` output
@return string hash The commit hash
@return string subject The commit subject message
@class CommitCategories
@field features string[] New functionality or capabilities
@field fixes string[] Bug fixes and corrections
@field perf string[] Performance improvements without changing behavior
@field docs string[] Documentation-only changes
@field refactor string[] Code restructuring without changing behavior
@field tests string[] Adding or updating tests
@field style string[] Formatting, whitespace, or cosmetic changes
@field chores string[] Maintenance and miscellaneous non-code tasks
@field ops string[] Operational changes: infrastructure, deployment, CI/CD, monitoring
@field reverts string[] Commits that revert a previous change
@field wip string[] Work-in-progress, not ready for review
@field breaking string[] Commits with BREAKING CHANGE text or ! marker (derived from other categories)
@field others string[] Commits not matching any conventional commit prefix
Parse and categorize a list of commit lines.
@param commit_lines string[] Lines from `git log --oneline` output
@param link_fn? fun(subject: string, hash?: string): string Optional function to add links
@return CommitCategories categories Commits grouped by category
@class FileStats
@field insertions number Number of lines added
@field deletions number Number of lines deleted
Parse `git diff --numstat` output into file statistics.
@param lines string[] Lines from `git diff --numstat` output
@return table<string, FileStats> stats Map of filepath to insertion/deletion counts
@class FileChange
@field status string Single-letter status (A=added, M=modified, D=deleted, R=renamed)
@field path string The file path
Parse `git diff --name-status` output into file changes.
@param lines string[] Lines from `git diff --name-status` output
@return FileChange[] files List of file changes with status and path
Parse total statistics from `git diff --stat` output.
Extracts the summary line (e.g., "5 files changed, 100 insertions(+), 20 deletions(-)").
@param file_stats_output string The full `git diff --stat` output
@return number total_files Number of files changed
@return number total_insertions Total lines inserted
@return number total_deletions Total lines deleted

