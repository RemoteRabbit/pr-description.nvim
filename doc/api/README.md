# API Reference

Auto-generated from LuaCATS annotations. Do not edit by hand;
run `make docs` to regenerate.

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

### `M.setup(opts)`

Setup pr-description.nvim with user options.

**Parameters:**

- `opts?` (`PrDescriptionConfig`)

### Type: `GenerateOpts`

- `is_gitlab?` (`boolean`) — Whether this is a GitLab MR (default: false, auto-detected from remote)
- `to_clipboard?` (`boolean`) — Copy result to clipboard (default: false)

### `M.generate_description(opts)`

Generate a PR/MR description from the current branch's commits.

**Parameters:**

- `opts?` (`GenerateOpts`)

**Returns:**

- `string|nil` — description The generated markdown description, or nil on error
- `string|nil` — error Error message if generation failed

## pr-description.config

Configuration for pr-description.nvim.

### Type: `PrDescriptionConfig`

- `auto_detect_platform?` (`boolean`) — Auto-detect GitHub vs GitLab from remote URL (default: true)
- `confirm_large_pr?` (`boolean`) — Prompt when more than `large_pr_threshold` commits (default: true)
- `enable_icons?` (`boolean`) — Include icons in final PR/MR pr-description (default: true)
- `enable_plugin_credit?` (`boolean`) — Include a credit link to pr-description.nvim in the footer (default: true)
- `enable_stats_footer?` (`boolean`) — Include stats footer in final PR/MR pr-description (default: true)
- `fetch_before_generate?` (`boolean`) — Fetch origin before generating to ensure accurate comparison (default: true)
- `jira_base_url?` (`string`) — Base URL for Jira ticket links (e.g., "https://company.atlassian.net/browse")
- `large_pr_threshold?` (`number`) — Number of commits before prompting (default: 10)
- `sections?` (`table<string, string>`) — Override section headers (key = category, value = markdown header)
- `strip_commit_prefix?` (`boolean`) — Strip conventional commit prefix/scope from output (default: true)

### `M.setup(opts)`

Apply user configuration.

**Parameters:**

- `opts?` (`PrDescriptionConfig`)

## pr-description.git

Git operations for PR description generation.

Provides functions for interacting with git to extract repository information,
branch details, commit history, and file change statistics.

### `M.check_repo()`

Check if current directory is inside a git repository.

**Returns:**

- `boolean|nil` — ok True if in a git repository, nil on error
- `string|nil` — error Error message if not in a repository

### `M.get_current_branch()`

Get the name of the current git branch.

**Returns:**

- `string|nil` — branch The current branch name
- `string|nil` — error Error message if branch could not be determined

### `M.detect_base_branch()`

Detect the base branch to compare against.
Tries origin/HEAD first, then falls back to origin/main, origin/master,
and finally local main/master branches.

**Returns:**

- `string|nil` — base_branch The detected base branch (e.g., "origin/main")
- `string|nil` — error Error message if no base branch could be detected

### `M.get_remote_url()`

Get the remote origin URL.

**Returns:**

- `string` — url The remote origin URL (may be empty if not configured)

### `M.fetch_origin()`

Fetch latest refs from origin to ensure accurate comparisons.

**Returns:**

- `boolean` — ok True if fetch succeeded or was skipped gracefully

### `M.get_merge_base(base_branch, branch)`

Find the merge-base (fork point) between two branches.

**Parameters:**

- `base_branch` (`string`) — The base branch
- `branch` (`string`) — The current branch

**Returns:**

- `string|nil` — merge_base The merge-base commit hash, or nil on error
- `string|nil` — error Error message if merge-base failed

### `M.get_commits(base_branch, branch)`

Get commit messages between base branch and current branch.
Uses merge-base to only include commits unique to the current branch.

**Parameters:**

- `base_branch` (`string`) — The base branch to compare from
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]|nil` — commits List of commit lines (hash + subject), or nil on error
- `string|nil` — error Error message if git log failed

### `M.get_commits_from(merge_base, branch)`

Get commit messages from a known merge-base to branch tip.

**Parameters:**

- `merge_base` (`string`) — The merge-base commit hash
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]|nil` — commits List of commit lines (hash + subject), or nil on error
- `string|nil` — error Error message if git log failed

### `M.get_file_changes(base_branch, branch)`

Get file change status (added, modified, deleted) between branches.
Uses merge-base for accurate comparison.

**Parameters:**

- `base_branch` (`string`) — The base branch to compare from
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]` — changes List of file changes in "status\tfilepath" format

### `M.get_file_changes_from(merge_base, branch)`

Get file change status from a known merge-base to branch tip.

**Parameters:**

- `merge_base` (`string`) — The merge-base commit hash or branch ref
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]` — changes List of file changes in "status\tfilepath" format

### `M.get_file_stats(base_branch, branch)`

Get human-readable file statistics (insertions/deletions summary).
Uses merge-base for accurate comparison.

**Parameters:**

- `base_branch` (`string`) — The base branch to compare from
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string` — stats The git diff --stat output as a single string

### `M.get_file_stats_from(merge_base, branch)`

Get human-readable file statistics from a known merge-base to branch tip.

**Parameters:**

- `merge_base` (`string`) — The merge-base commit hash or branch ref
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string` — stats The git diff --stat output as a single string

### `M.get_file_numstat(base_branch, branch)`

Get machine-readable file statistics (insertions/deletions per file).
Uses merge-base for accurate comparison.

**Parameters:**

- `base_branch` (`string`) — The base branch to compare from
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]` — numstat List of lines in "insertions\tdeletions\tfilepath" format

### `M.get_file_numstat_from(merge_base, branch)`

Get machine-readable file statistics from a known merge-base to branch tip.

**Parameters:**

- `merge_base` (`string`) — The merge-base commit hash or branch ref
- `branch` (`string`) — The current branch to compare to

**Returns:**

- `string[]` — numstat List of lines in "insertions\tdeletions\tfilepath" format

## pr-description.parser

Conventional commit parsing and categorization.

Parses git commits following the conventional commit specification and
categorizes them into groups (features, fixes, docs, etc.). Also handles
parsing of git diff statistics for file change analysis.

### `M.strip_prefix(subject)`

Strip the conventional commit prefix and optional scope from a subject.
Transforms "feat(auth): add login" to "add login", "fix!: crash" to "crash".
Returns the subject unchanged if it doesn't match a conventional pattern.

**Parameters:**

- `subject` (`string`) — The commit subject line

**Returns:**

- `string` — stripped The subject without the conventional commit prefix

### `M.categorize_commit(subject)`

Categorize a commit subject based on conventional commit prefixes.

**Parameters:**

- `subject` (`string`) — The commit subject line

**Returns:**

- `string` — category The category name (e.g., "features", "fixes", "others")

### `M.is_breaking_change(subject)`

Check if a commit subject indicates a breaking change.
Detects "BREAKING CHANGE" text or "!" marker in conventional commits.

**Parameters:**

- `subject` (`string`) — The commit subject line

**Returns:**

- `boolean` — is_breaking True if this is a breaking change

### `M.parse_commit_line(line)`

Parse a single commit line into hash and subject.

**Parameters:**

- `line` (`string`) — A line from `git log --oneline` output

**Returns:**

- `string` — hash The commit hash
- `string` — subject The commit subject message

### Type: `CommitCategories`

- `features` (`string[]`) — New functionality or capabilities
- `fixes` (`string[]`) — Bug fixes and corrections
- `perf` (`string[]`) — Performance improvements without changing behavior
- `docs` (`string[]`) — Documentation-only changes
- `refactor` (`string[]`) — Code restructuring without changing behavior
- `tests` (`string[]`) — Adding or updating tests
- `style` (`string[]`) — Formatting, whitespace, or cosmetic changes
- `chores` (`string[]`) — Maintenance and miscellaneous non-code tasks
- `ops` (`string[]`) — Operational changes: infrastructure, deployment, CI/CD, monitoring
- `reverts` (`string[]`) — Commits that revert a previous change
- `wip` (`string[]`) — Work-in-progress, not ready for review
- `breaking` (`string[]`) — Commits with BREAKING CHANGE text or ! marker (derived from other categories)
- `others` (`string[]`) — Commits not matching any conventional commit prefix

### Type: `ParseCommitsCallbacks`

- `process_subject?` (`fun(subject: string): string`) — Add links to a commit subject
- `make_commit_link?` (`fun(hash: string): string`) — Create a markdown link for a commit hash
- `strip_prefix?` (`boolean`) — Strip conventional commit prefix/scope from display text

### `M.parse_commits(commit_lines, callbacks)`

Parse and categorize a list of commit lines.

**Parameters:**

- `commit_lines` (`string[]`) — Lines from `git log --oneline` output
- `callbacks?` (`ParseCommitsCallbacks`) — Optional callbacks for link processing

**Returns:**

- `CommitCategories` — categories Commits grouped by category

### Type: `FileStats`

- `insertions` (`number`) — Number of lines added
- `deletions` (`number`) — Number of lines deleted

### `M.resolve_rename_path(raw)`

Resolve a rename path from git's `{old => new}` notation to the new path.
Handles formats: `prefix/{old => new}/suffix`, `{old => new}`, `old => new`.

**Parameters:**

- `raw` (`string`) — The raw path from git output

**Returns:**

- `string` — filepath The resolved new file path

### `M.parse_file_numstat(lines)`

Parse `git diff --numstat` output into file statistics.

**Parameters:**

- `lines` (`string[]`) — Lines from `git diff --numstat` output

**Returns:**

- `table<string, FileStats>` — stats Map of filepath to insertion/deletion counts

### Type: `FileChange`

- `status` (`string`) — Single-letter status (A=added, M=modified, D=deleted, R=renamed)
- `path` (`string`) — The file path

### `M.parse_file_changes(lines)`

Parse `git diff --name-status` output into file changes.

**Parameters:**

- `lines` (`string[]`) — Lines from `git diff --name-status` output

**Returns:**

- `FileChange[]` — files List of file changes with status and path

### `M.parse_total_stats(file_stats_output)`

Parse total statistics from `git diff --stat` output.
Extracts the summary line (e.g., "5 files changed, 100 insertions(+), 20 deletions(-)").

**Parameters:**

- `file_stats_output` (`string`) — The full `git diff --stat` output

**Returns:**

- `number` — total_files Number of files changed
- `number` — total_insertions Total lines inserted
- `number` — total_deletions Total lines deleted

## pr-description.links

URL parsing and link generation for PR descriptions.

Handles parsing of git remote URLs (SSH and HTTPS formats), building
repository URLs, and generating markdown links for issues, Jira tickets,
and commit references.

### `M.parse_remote_url(url)`

Parse a git remote URL into host and path components.
Supports SSH (git@host:path or ssh://git@host/path) and HTTPS formats.

**Parameters:**

- `url` (`string`) — The git remote URL

**Returns:**

- `string|nil` — host The hostname (e.g., "github.com")
- `string|nil` — path The repository path (e.g., "owner/repo")

### `M.build_repo_url(host, path)`

Build a full HTTPS repository URL from host and path.

**Parameters:**

- `host` (`string|nil`) — The hostname (e.g., "github.com")
- `path` (`string|nil`) — The repository path (e.g., "owner/repo")

**Returns:**

- `string` — url The full repository URL, or empty string if host/path is nil

### `M.is_gitlab_host(host)`

Check if a host is a GitLab instance.

**Parameters:**

- `host` (`string|nil`) — The hostname to check

**Returns:**

- `boolean` — is_gitlab True if the host contains "gitlab"

### `M.add_issue_links(text, repo_url, is_gitlab)`

Add markdown links to issue references (e.g., "fixes #123").
Converts patterns like "fixes #123" to "fixes [#123](repo_url/issues/123)".

**Parameters:**

- `text` (`string`) — The text to process
- `repo_url` (`string`) — The repository base URL
- `is_gitlab` (`boolean`) — Whether to use GitLab URL format (/-/issues/)

**Returns:**

- `string` — text The text with issue references converted to links

### `M.add_jira_links(text, base_url)`

Add markdown links to Jira ticket references (e.g., "PROJ-123").

**Parameters:**

- `text` (`string`) — The text to process
- `base_url?` (`string`) — Jira base URL (e.g., "https://company.atlassian.net/browse")

**Returns:**

- `string` — text The text with Jira tickets converted to links

### `M.add_all_links(text, repo_url, is_gitlab, jira_base_url)`

Add all supported markdown links (issues and Jira tickets).

**Parameters:**

- `text` (`string`) — The text to process
- `repo_url` (`string`) — The repository base URL
- `is_gitlab` (`boolean`) — Whether to use GitLab URL format
- `jira_base_url?` (`string`) — Jira base URL for ticket links

**Returns:**

- `string` — text The text with all references converted to links

### `M.make_commit_link(hash, repo_url, is_gitlab)`

Create a markdown link to a commit.

**Parameters:**

- `hash` (`string`) — The commit hash (short or full)
- `repo_url` (`string`) — The repository base URL
- `is_gitlab` (`boolean`) — Whether to use GitLab URL format (/-/commit/)

**Returns:**

- `string` — link The markdown link, or empty string if repo_url is empty

## pr-description.formatter

Markdown generation for PR descriptions.

Formats categorized commits and file changes into a well-structured
markdown document suitable for GitHub PRs or GitLab MRs. Includes
emoji indicators, collapsible sections, and statistics.

### `M.add_summary_section(lines)`

Add the summary placeholder section to the output.

**Parameters:**

- `lines` (`string[]`) — The output lines table (modified in place)

### `M.add_category_sections(lines, categories)`

Add categorized commit sections to the output.
Only adds sections for categories that have commits.

**Parameters:**

- `lines` (`string[]`) — The output lines table (modified in place)
- `categories` (`CommitCategories`) — The categorized commits

### `M.determine_file_group(filepath)`

Determine which logical group a file belongs to based on its path.
Groups files by top-level directory or special patterns (tests, docs, config).

**Parameters:**

- `filepath` (`string`) — The file path

**Returns:**

- `string` — group The group name (e.g., "Root", "Tests", "Documentation")

### Type: `FileInfo`

- `path` (`string`) — The file path
- `symbol` (`string`) — Emoji status symbol
- `stats` (`string`) — Formatted stats string (e.g., " (+10/-5)")

### `M.group_files(file_list, file_stats)`

Group files by their logical directory/category.

**Parameters:**

- `file_list` (`FileChange[]`) — List of file changes
- `file_stats` (`table<string, FileStats>`) — Map of filepath to statistics

**Returns:**

- `table<string, FileInfo[]>` — groups Files grouped by category name

### `M.sort_groups(groups)`

Sort group names by predefined priority (Root first, Tests/Docs last).

**Parameters:**

- `groups` (`table<string, FileInfo[]>`) — The groups to sort

**Returns:**

- `string[]` — sorted_names Group names in sorted order

### `M.add_file_changes_section(lines, file_groups, file_stats)`

Add the file changes section to the output.
Lists files grouped by category with statistics.

**Parameters:**

- `lines` (`string[]`) — The output lines table (modified in place)
- `file_groups` (`table<string, FileInfo[]>`) — Files grouped by category
- `file_stats` (`table<string, FileStats>`) — Map of filepath to statistics

### Type: `DescriptionStats`

- `total_files` (`number`) — Total number of files changed
- `total_insertions` (`number`) — Total lines inserted
- `total_deletions` (`number`) — Total lines deleted
- `total_commits` (`number`) — Total number of commits
- `branch` (`string`) — Current branch name
- `base_branch` (`string`) — Base branch name

### `M.add_footer(lines, stats)`

Add the footer section with summary statistics.

**Parameters:**

- `lines` (`string[]`) — The output lines table (modified in place)
- `stats` (`DescriptionStats`) — Summary statistics

### `M.add_plugin_credit(lines)`

Add a credit link back to pr-description.nvim.

**Parameters:**

- `lines` (`string[]`) — The output lines table (modified in place)

### `M.generate(categories, file_groups, file_stats, stats)`

Generate the complete PR/MR description.

**Parameters:**

- `categories` (`CommitCategories`) — Categorized commits
- `file_groups` (`table<string, FileInfo[]>`) — Files grouped by category
- `file_stats` (`table<string, FileStats>`) — Map of filepath to statistics
- `stats` (`DescriptionStats`) — Summary statistics

**Returns:**

- `string` — description The complete markdown description
