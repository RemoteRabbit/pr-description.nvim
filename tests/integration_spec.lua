local pr = require("pr-description")
local config = require("pr-description.config")

---Create a temporary git repo with conventional commits on a feature branch.
---@return string tmpdir The temporary directory path
local function setup_test_repo()
  local tmpdir = vim.fn.tempname()
  vim.fn.mkdir(tmpdir, "p")

  local function run(cmd)
    vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && " .. cmd)
  end

  run("git init -b main")
  run("git config user.email 'test@test.com'")
  run("git config user.name 'Test'")
  run("git config commit.gpgsign false")

  -- Initial commit on main
  run("echo 'init' > file.txt")
  run("git add file.txt")
  run("git commit -m 'chore: initial commit'")

  -- Feature branch with mixed conventional commits
  run("git checkout -b feat/user-auth")
  run("mkdir -p src/auth")
  run("echo 'module' > src/auth/login.lua")
  run("git add -A")
  run("git commit -m 'feat(auth): add login module'")

  run("echo 'fix' >> src/auth/login.lua")
  run("git add -A")
  run("git commit -m 'fix: resolve token validation'")

  run("echo 'docs' > README.md")
  run("git add -A")
  run("git commit -m 'docs: add project readme'")

  run("echo 'test' > tests/auth_spec.lua")
  run("mkdir -p tests && echo 'test' > tests/auth_spec.lua")
  run("git add -A")
  run("git commit -m 'test: add auth tests'")

  return tmpdir
end

describe("integration", function()
  local tmpdir
  local orig_dir

  before_each(function()
    orig_dir = vim.fn.getcwd()
    tmpdir = setup_test_repo()
    vim.cmd("cd " .. tmpdir)
    config.setup({
      confirm_large_pr = false,
      fetch_before_generate = false,
      strip_commit_prefix = true,
      enable_icons = true,
      enable_stats_footer = true,
    })
  end)

  after_each(function()
    vim.cmd("cd " .. orig_dir)
    vim.fn.system("rm -rf " .. vim.fn.shellescape(tmpdir))
  end)

  describe("full description from a real branch", function()
    it("produces valid markdown with all expected sections", function()
      local desc, err = pr.generate_description()
      assert.is_nil(err)
      assert.truthy(desc)

      -- Summary section
      assert.truthy(desc:find("## Summary", 1, true))
      assert.truthy(desc:find("_Brief description of changes_", 1, true))

      -- Commit category sections with icons
      assert.truthy(desc:find("## ✨ Features", 1, true))
      assert.truthy(desc:find("## 🐛 Bug Fixes", 1, true))
      assert.truthy(desc:find("## 📚 Documentation", 1, true))
      assert.truthy(desc:find("## 🧪 Tests", 1, true))

      -- File changes section
      assert.truthy(desc:find("## 📁 File Changes", 1, true))
    end)

    it("strips conventional commit prefixes from entries", function()
      local desc = pr.generate_description()

      -- Should show clean descriptions, not raw prefixes
      assert.truthy(desc:find("add login module"))
      assert.truthy(desc:find("resolve token validation"))
      assert.truthy(desc:find("add project readme"))
      assert.truthy(desc:find("add auth tests"))

      -- Should NOT contain the raw prefix in the list items
      assert.falsy(desc:find("- feat%(auth%):"))
      assert.falsy(desc:find("- fix:"))
      assert.falsy(desc:find("- docs:"))
      assert.falsy(desc:find("- test:"))
    end)

    it("preserves prefixes when strip_commit_prefix is false", function()
      config.setup({
        confirm_large_pr = false,
        fetch_before_generate = false,
        strip_commit_prefix = false,
      })
      local desc = pr.generate_description()

      assert.truthy(desc:find("feat%(auth%): add login module"))
      assert.truthy(desc:find("fix: resolve token validation"))
    end)

    it("includes file stats in footer", function()
      local desc = pr.generate_description()

      assert.truthy(desc:find("**Commits:** 4", 1, true))
      assert.truthy(desc:find("**Branch:** `feat/user-auth`", 1, true))
      assert.truthy(desc:find("**Base:** `main`", 1, true))
      assert.truthy(desc:find("**Changes:**"))
    end)

    it("omits icons when enable_icons is false", function()
      config.setup({
        confirm_large_pr = false,
        fetch_before_generate = false,
        enable_icons = false,
      })
      local desc = pr.generate_description()

      assert.truthy(desc:find("## Features", 1, true))
      assert.truthy(desc:find("## Bug Fixes", 1, true))
      assert.truthy(desc:find("## File Changes", 1, true))
      assert.falsy(desc:find("✨"))
      assert.falsy(desc:find("🐛"))
      assert.falsy(desc:find("📁"))
    end)

    it("omits footer when enable_stats_footer is false", function()
      config.setup({
        confirm_large_pr = false,
        fetch_before_generate = false,
        enable_stats_footer = false,
      })
      local desc = pr.generate_description()

      assert.falsy(desc:find("**Changes:**", 1, true))
      assert.falsy(desc:find("**Commits:**", 1, true))
      assert.falsy(desc:find("**Branch:**", 1, true))
    end)

    it("groups files into correct categories", function()
      local desc = pr.generate_description()

      -- src/auth/login.lua should be grouped under Auth (src subdirectory)
      assert.truthy(desc:find("### Auth"))
      assert.truthy(desc:find("`src/auth/login.lua`"))

      -- README.md should be grouped under Documentation
      assert.truthy(desc:find("### Documentation"))
      assert.truthy(desc:find("`README.md`"))

      -- tests/auth_spec.lua should be grouped under Tests
      assert.truthy(desc:find("### Tests"))
      assert.truthy(desc:find("`tests/auth_spec.lua`"))
    end)

    it("renders sections in correct order", function()
      local desc = pr.generate_description()

      local summary_pos = desc:find("## Summary", 1, true)
      local features_pos = desc:find("## ✨ Features", 1, true)
      local fixes_pos = desc:find("## 🐛 Bug Fixes", 1, true)
      local docs_pos = desc:find("## 📚 Documentation", 1, true)
      local tests_pos = desc:find("## 🧪 Tests", 1, true)
      local files_pos = desc:find("## 📁 File Changes", 1, true)

      -- Verify ordering: Summary -> Features -> Fixes -> Docs -> Tests -> File Changes
      assert.truthy(summary_pos < features_pos)
      assert.truthy(features_pos < fixes_pos)
      assert.truthy(fixes_pos < docs_pos)
      assert.truthy(docs_pos < tests_pos)
      assert.truthy(tests_pos < files_pos)
    end)

    it("includes per-file stats in file changes", function()
      local desc = pr.generate_description()

      -- File entries should have +/- stats
      assert.truthy(desc:find("`src/auth/login.lua`.*%+%d"))
      assert.truthy(desc:find("`README.md`.*%+%d"))
    end)

    it("includes group-level aggregated stats", function()
      local desc = pr.generate_description()

      -- Group headers should have (+N/-N lines) format
      assert.truthy(desc:find("### Auth %(%+%d+/%-?%d+ lines%)"))
      assert.truthy(desc:find("### Documentation %(%+%d+/%-?%d+ lines%)"))
    end)
  end)

  describe("edge cases on real branches", function()
    it("handles a branch with a single commit", function()
      -- Create a new branch with one commit
      vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && git checkout main")
      vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && git checkout -b feat/single")
      vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && echo 'one' > single.txt && git add -A && git commit -m 'feat: single change'")

      local desc, err = pr.generate_description()
      assert.is_nil(err)
      assert.truthy(desc:find("## ✨ Features", 1, true))
      assert.truthy(desc:find("**Commits:** 1", 1, true))
    end)

    it("handles non-conventional commits under Other Changes", function()
      vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && echo 'misc' > misc.txt && git add -A && git commit -m 'random update'")

      local desc = pr.generate_description()
      assert.truthy(desc:find("## 📦 Other Changes", 1, true))
      assert.truthy(desc:find("random update"))
    end)

    it("handles breaking changes", function()
      vim.fn.system("cd " .. vim.fn.shellescape(tmpdir) .. " && echo 'break' > break.txt && git add -A && git commit -m 'feat!: remove deprecated API'")

      local desc = pr.generate_description()
      assert.truthy(desc:find("## ⚠️ Breaking Changes", 1, true))
      assert.truthy(desc:find("remove deprecated API"))
    end)
  end)
end)
