local parser = require("pr-description.parser")

describe("parser", function()
  describe("categorize_commit", function()
    it("categorizes feature commits", function()
      assert.equals("features", parser.categorize_commit("feat: add new feature"))
      assert.equals("features", parser.categorize_commit("feat(scope): add new feature"))
      assert.equals("features", parser.categorize_commit("feature: add new feature"))
    end)

    it("categorizes fix commits", function()
      assert.equals("fixes", parser.categorize_commit("fix: resolve bug"))
      assert.equals("fixes", parser.categorize_commit("fix(auth): resolve bug"))
      assert.equals("fixes", parser.categorize_commit("bugfix: resolve bug"))
    end)

    it("categorizes docs commits", function()
      assert.equals("docs", parser.categorize_commit("docs: update readme"))
      assert.equals("docs", parser.categorize_commit("doc: update readme"))
    end)

    it("categorizes perf commits", function()
      assert.equals("perf", parser.categorize_commit("perf: optimize query"))
      assert.equals("perf", parser.categorize_commit("perf(db): reduce allocations"))
    end)

    it("categorizes refactor commits", function()
      assert.equals("refactor", parser.categorize_commit("refactor: clean up code"))
      assert.equals("refactor", parser.categorize_commit("refactor(core): clean up"))
    end)

    it("categorizes test commits", function()
      assert.equals("tests", parser.categorize_commit("test: add tests"))
      assert.equals("tests", parser.categorize_commit("tests: add tests"))
    end)

    it("categorizes chore commits", function()
      assert.equals("chores", parser.categorize_commit("chore: update deps"))
    end)

    it("categorizes ops commits", function()
      assert.equals("ops", parser.categorize_commit("ops: update deployment"))
      assert.equals("ops", parser.categorize_commit("ops(k8s): scale replicas"))
      assert.equals("ops", parser.categorize_commit("ci: update workflow"))
      assert.equals("ops", parser.categorize_commit("build: update config"))
    end)

    it("categorizes revert commits", function()
      assert.equals("reverts", parser.categorize_commit("revert: undo feature"))
      assert.equals("reverts", parser.categorize_commit("revert(auth): undo change"))
    end)

    it("returns others for uncategorized commits", function()
      assert.equals("others", parser.categorize_commit("update something"))
      assert.equals("others", parser.categorize_commit("random commit"))
    end)
  end)

  describe("is_breaking_change", function()
    it("detects BREAKING CHANGE text", function()
      assert.is_true(parser.is_breaking_change("feat: BREAKING CHANGE something"))
    end)

    it("detects bang notation", function()
      assert.is_true(parser.is_breaking_change("feat!: something"))
    end)

    it("detects bang with scope", function()
      assert.is_true(parser.is_breaking_change("feat(api)!: something"))
    end)

    it("returns false for normal commits", function()
      assert.is_falsy(parser.is_breaking_change("feat: normal feature"))
    end)
  end)

  describe("parse_commit_line", function()
    it("splits hash and subject", function()
      local hash, subject = parser.parse_commit_line("abc1234 feat: add feature")
      assert.equals("abc1234", hash)
      assert.equals("feat: add feature", subject)
    end)
  end)

  describe("parse_file_numstat", function()
    it("parses numstat lines", function()
      local stats = parser.parse_file_numstat({
        "10\t5\tsrc/main.lua",
        "3\t0\tREADME.md",
      })
      assert.equals(10, stats["src/main.lua"].insertions)
      assert.equals(5, stats["src/main.lua"].deletions)
      assert.equals(3, stats["README.md"].insertions)
      assert.equals(0, stats["README.md"].deletions)
    end)

    it("handles binary files", function()
      local stats = parser.parse_file_numstat({
        "-\t-\timage.png",
      })
      assert.equals(0, stats["image.png"].insertions)
      assert.equals(0, stats["image.png"].deletions)
    end)
  end)

  describe("parse_file_changes", function()
    it("parses name-status output", function()
      local files = parser.parse_file_changes({
        "A\tsrc/new.lua",
        "M\tsrc/existing.lua",
        "D\tsrc/old.lua",
      })
      assert.equals(3, #files)
      assert.equals("A", files[1].status)
      assert.equals("src/new.lua", files[1].path)
    end)
  end)

  describe("parse_total_stats", function()
    it("parses stat summary line", function()
      local files, ins, dels = parser.parse_total_stats(
        " src/a.lua | 10 ++++\n src/b.lua |  5 ---\n 2 files changed, 10 insertions(+), 5 deletions(-)\n"
      )
      assert.equals(2, files)
      assert.equals(10, ins)
      assert.equals(5, dels)
    end)

    it("handles empty input", function()
      local files, ins, dels = parser.parse_total_stats("")
      assert.equals(0, files)
      assert.equals(0, ins)
      assert.equals(0, dels)
    end)
  end)
end)
