# pr-description.nvim

Generate well-formatted PR/MR descriptions from your git commits.

Analyzes commits using [conventional commit](https://www.conventionalcommits.org/) patterns, categorizes them, links issues and Jira tickets, and produces markdown output for GitHub PRs or GitLab MRs.

## Features

- 📝 Conventional commit categorization (features, fixes, docs, etc.)
- 🔗 Auto-links GitHub/GitLab issues and Jira tickets
- 📊 File change statistics grouped by directory
- 🔍 Auto-detects GitHub vs GitLab from remote URL
- 📋 Copy to clipboard with bang commands

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "remoterabbit/pr-description.nvim",
  cmd = { "PRDescription", "MRDescription" },
  opts = {},
}
```

## Configuration

```lua
require("pr-description").setup({
  -- Base URL for Jira ticket links (nil = disabled)
  jira_base_url = nil,

  -- Auto-detect GitHub vs GitLab from remote URL
  auto_detect_platform = true,

  -- Prompt when commits exceed threshold
  confirm_large_pr = true,
  large_pr_threshold = 10,

  -- Override section headers (key = category, value = markdown header)
  sections = nil,
})
```

## Usage

| Command | Description |
|---|---|
| `:PRDescription` | Generate GitHub PR description in a scratch buffer |
| `:PRDescription!` | Generate and copy to clipboard |
| `:MRDescription` | Generate GitLab MR description in a scratch buffer |
| `:MRDescription!` | Generate and copy to clipboard |

### Lua API

```lua
local pr = require("pr-description")
local description, err = pr.generate_description({ is_gitlab = false, to_clipboard = true })
```

### Headless / CLI

```bash
nvim --headless -c "lua print(require('pr-description').generate_description())" -c "qa"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and guidelines.

## Helpful Links

- [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/)
- [Conventional Commit Messages Cheatsheet](https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13)

## License

[Unlicense](https://unlicense.org) — public domain
