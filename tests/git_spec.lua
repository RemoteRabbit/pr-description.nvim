local git = require("pr-description.git")

---Create a temporary git repo with a branch for testing.
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

  -- Create initial commit on main
  run("echo 'initial' > file.txt")
  run("git add file.txt")
  run("git commit -m 'chore: initial commit'")

  -- Create a feature branch with commits
  run("git checkout -b feat/test")
  run("mkdir -p src")
  run("echo 'feature' > src/main.lua")
  run("git add -A")
  run("git commit -m 'feat: add main module'")
  run("echo 'fix' >> src/main.lua")
  run("git add -A")
  run("git commit -m 'fix: resolve startup crash'")

  return tmpdir
end

describe("git", function()
  local tmpdir
  local orig_dir

  before_each(function()
    orig_dir = vim.fn.getcwd()
    tmpdir = setup_test_repo()
    vim.cmd("cd " .. tmpdir)
  end)

  after_each(function()
    vim.cmd("cd " .. orig_dir)
    vim.fn.system("rm -rf " .. vim.fn.shellescape(tmpdir))
  end)

  describe("check_repo", function()
    it("returns true inside a git repo", function()
      local ok, err = git.check_repo()
      assert.is_true(ok)
      assert.is_nil(err)
    end)

    it("returns nil and error outside a git repo", function()
      local non_git = vim.fn.tempname()
      vim.fn.mkdir(non_git, "p")
      vim.cmd("cd " .. non_git)
      local ok, err = git.check_repo()
      assert.is_nil(ok)
      assert.equals("Not in a git repository", err)
      vim.fn.system("rm -rf " .. vim.fn.shellescape(non_git))
    end)
  end)

  describe("get_current_branch", function()
    it("returns the branch name", function()
      local branch, err = git.get_current_branch()
      assert.equals("feat/test", branch)
      assert.is_nil(err)
    end)

    it("returns error on detached HEAD", function()
      vim.fn.system("git checkout --detach HEAD")
      local branch, err = git.get_current_branch()
      assert.is_nil(branch)
      assert.truthy(err:find("detached HEAD"))
    end)
  end)

  describe("detect_base_branch", function()
    it("detects local main branch", function()
      local base, err = git.detect_base_branch()
      assert.equals("main", base)
      assert.is_nil(err)
    end)
  end)

  describe("get_remote_url", function()
    it("returns empty string when no remote configured", function()
      local url = git.get_remote_url()
      assert.equals("string", type(url))
    end)

    it("returns only the string, not gsub count", function()
      local url, extra = git.get_remote_url()
      assert.equals("string", type(url))
      assert.is_nil(extra)
    end)

    it("returns configured remote URL", function()
      vim.fn.system("git remote add origin https://github.com/user/repo.git")
      local url = git.get_remote_url()
      assert.equals("https://github.com/user/repo.git", url)
    end)
  end)

  describe("get_merge_base", function()
    it("returns the merge-base hash", function()
      local result, err = git.get_merge_base("main", "feat/test")
      assert.truthy(result)
      assert.truthy(result:match("^%x+$"))
      assert.is_nil(err)
    end)

    it("returns error for nonexistent branch", function()
      local result, err = git.get_merge_base("main", "nonexistent")
      assert.is_nil(result)
      assert.truthy(err:find("merge%-base"))
    end)
  end)

  describe("get_commits", function()
    it("returns commits between main and feature branch", function()
      local commits, err = git.get_commits("main", "feat/test")
      assert.is_nil(err)
      assert.equals(2, #commits)
    end)

    it("returns error for nonexistent branch", function()
      local commits, err = git.get_commits("main", "nonexistent")
      assert.is_nil(commits)
      assert.truthy(err)
    end)
  end)

  describe("get_commits_from", function()
    it("returns commits from merge-base", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local commits, err = git.get_commits_from(merge_base, "feat/test")
      assert.is_nil(err)
      assert.equals(2, #commits)
    end)

    it("returns empty list when no commits ahead", function()
      local head = vim.fn.system("git rev-parse HEAD"):gsub("\n", "")
      local commits, err = git.get_commits_from(head, "feat/test")
      assert.is_nil(err)
      assert.equals(0, #commits)
    end)
  end)

  describe("get_file_changes_from", function()
    it("returns file changes", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local changes = git.get_file_changes_from(merge_base, "feat/test")
      assert.truthy(#changes > 0)
      local found = false
      for _, line in ipairs(changes) do
        if line:find("src/main.lua") then
          found = true
        end
      end
      assert.is_true(found)
    end)
  end)

  describe("get_file_stats_from", function()
    it("returns stat summary", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local stats = git.get_file_stats_from(merge_base, "feat/test")
      assert.truthy(stats:find("changed"))
    end)
  end)

  describe("get_file_numstat_from", function()
    it("returns numstat lines", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local lines = git.get_file_numstat_from(merge_base, "feat/test")
      assert.truthy(#lines > 0)
      assert.truthy(lines[1]:find("\t"))
    end)
  end)

  describe("fetch_origin", function()
    it("returns false when no remote configured", function()
      assert.is_false(git.fetch_origin())
    end)
  end)

  describe("convenience wrappers delegate to _from variants", function()
    it("get_file_changes matches direct call", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local via_wrapper = git.get_file_changes("main", "feat/test")
      local via_direct = git.get_file_changes_from(merge_base, "feat/test")
      assert.same(via_wrapper, via_direct)
    end)

    it("get_file_stats matches direct call", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local via_wrapper = git.get_file_stats("main", "feat/test")
      local via_direct = git.get_file_stats_from(merge_base, "feat/test")
      assert.equals(via_wrapper, via_direct)
    end)

    it("get_file_numstat matches direct call", function()
      local merge_base = git.get_merge_base("main", "feat/test")
      local via_wrapper = git.get_file_numstat("main", "feat/test")
      local via_direct = git.get_file_numstat_from(merge_base, "feat/test")
      assert.same(via_wrapper, via_direct)
    end)
  end)
end)
