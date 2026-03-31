local pr = require("pr-description")
local config = require("pr-description.config")
local git = require("pr-description.git")

---@type table<string, fun(...): any>
local stubs = {}

---Replace git module functions with stubs for integration testing.
---@param overrides table<string, any> Map of function name to return value(s)
local function stub_git(overrides)
  stubs = {}
  for name, fn in pairs(git) do
    if type(fn) == "function" then
      stubs[name] = fn
    end
  end

  git.check_repo = function()
    return true
  end
  git.get_current_branch = function()
    return "feat/test"
  end
  git.fetch_origin = function()
    return true
  end
  git.detect_base_branch = function()
    return "origin/main"
  end
  git.get_remote_url = function()
    return "git@github.com:user/repo.git"
  end
  git.get_merge_base = function()
    return "abc123"
  end
  git.get_commits_from = function()
    return { "abc1234 feat: add login", "def5678 fix: resolve crash" }
  end
  git.get_file_changes_from = function()
    return { "A\tsrc/main.lua", "M\tREADME.md" }
  end
  git.get_file_stats_from = function()
    return " 2 files changed, 15 insertions(+), 3 deletions(-)\n"
  end
  git.get_file_numstat_from = function()
    return { "10\t2\tsrc/main.lua", "5\t1\tREADME.md" }
  end

  for name, value in pairs(overrides or {}) do
    if type(value) == "function" then
      git[name] = value
    else
      git[name] = function()
        return value
      end
    end
  end
end

---Restore original git module functions.
local function restore_git()
  for name, fn in pairs(stubs) do
    git[name] = fn
  end
  stubs = {}
end

describe("init", function()
  before_each(function()
    config.setup({
      confirm_large_pr = false,
      fetch_before_generate = false,
    })
  end)

  after_each(function()
    restore_git()
  end)

  describe("generate_description", function()
    it("produces a description with all sections", function()
      stub_git()
      local desc, err = pr.generate_description()
      assert.is_nil(err)
      assert.truthy(desc)
      assert.truthy(desc:find("Summary"))
      assert.truthy(desc:find("Features"))
      assert.truthy(desc:find("Bug Fixes"))
      assert.truthy(desc:find("File Changes"))
    end)

    it("returns error when not in a git repo", function()
      stub_git({
        check_repo = function()
          return nil, "Not in a git repository"
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.equals("Not in a git repository", err)
    end)

    it("returns error when branch cannot be determined", function()
      stub_git({
        get_current_branch = function()
          return nil, "Could not determine current branch (detached HEAD?)"
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.truthy(err:find("detached HEAD"))
    end)

    it("returns error when base branch not found", function()
      stub_git({
        detect_base_branch = function()
          return nil, "Could not detect base branch"
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.truthy(err:find("Could not detect base branch"))
    end)

    it("returns error when merge-base fails", function()
      stub_git({
        get_merge_base = function()
          return nil, "Failed to find merge-base"
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.truthy(err:find("merge%-base"))
    end)

    it("returns error when no commits found", function()
      stub_git({
        get_commits_from = function()
          return {}
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.truthy(err:find("No commits found"))
    end)

    it("returns error when git log fails", function()
      stub_git({
        get_commits_from = function()
          return nil, "Failed to get commits: git log failed"
        end,
      })
      local desc, err = pr.generate_description()
      assert.is_nil(desc)
      assert.truthy(err:find("git log failed"))
    end)

    it("includes commit links in output", function()
      stub_git()
      local desc = pr.generate_description()
      assert.truthy(desc:find("%[`abc1234`%]"))
      assert.truthy(desc:find("github.com/user/repo/commit/"))
    end)

    it("includes file stats in footer", function()
      stub_git()
      local desc = pr.generate_description()
      assert.truthy(desc:find("**Changes:** 2 files", 1, true))
      assert.truthy(desc:find("**Branch:** `feat/test`", 1, true))
      assert.truthy(desc:find("**Base:** `origin/main`", 1, true))
    end)

    it("omits footer when enable_stats_footer is false", function()
      config.setup({ confirm_large_pr = false, fetch_before_generate = false, enable_stats_footer = false })
      stub_git()
      local desc = pr.generate_description()
      assert.falsy(desc:find("**Changes:**", 1, true))
    end)

    it("uses GitLab paths when is_gitlab is set", function()
      stub_git({
        get_remote_url = function()
          return "git@gitlab.com:user/repo.git"
        end,
      })
      local desc = pr.generate_description({ is_gitlab = true })
      assert.truthy(desc:find("gitlab.com/user/repo/%-/commit/"))
    end)

    it("auto-detects GitLab from remote URL", function()
      stub_git({
        get_remote_url = function()
          return "git@gitlab.com:user/repo.git"
        end,
      })
      local desc = pr.generate_description()
      assert.truthy(desc:find("gitlab.com/user/repo/%-/commit/"))
    end)

    it("strips commit prefix by default", function()
      stub_git({
        get_commits_from = function()
          return { "abc1234 feat(auth): add login" }
        end,
      })
      local desc = pr.generate_description()
      assert.truthy(desc:find("add login"))
      assert.falsy(desc:find("feat%(auth%)"))
    end)

    it("preserves commit prefix when strip_commit_prefix is false", function()
      config.setup({ confirm_large_pr = false, fetch_before_generate = false, strip_commit_prefix = false })
      stub_git({
        get_commits_from = function()
          return { "abc1234 feat(auth): add login" }
        end,
      })
      local desc = pr.generate_description()
      assert.truthy(desc:find("feat%(auth%): add login"))
    end)

    it("copies to clipboard when to_clipboard is set", function()
      stub_git()
      local setreg_calls = {}
      local orig_setreg = vim.fn.setreg
      vim.fn.setreg = function(reg, val)
        table.insert(setreg_calls, { reg = reg, val = val })
        return orig_setreg(reg, val)
      end
      local desc = pr.generate_description({ to_clipboard = true })
      vim.fn.setreg = orig_setreg
      assert.truthy(desc)
      assert.equals(1, #setreg_calls)
      assert.equals("+", setreg_calls[1].reg)
      assert.equals(desc, setreg_calls[1].val)
    end)
  end)

  describe("setup", function()
    it("applies user config", function()
      pr.setup({ large_pr_threshold = 50 })
      assert.equals(50, config.options.large_pr_threshold)
    end)

    it("preserves defaults for unset options", function()
      pr.setup({ large_pr_threshold = 50 })
      assert.is_true(config.options.enable_icons)
    end)
  end)
end)
