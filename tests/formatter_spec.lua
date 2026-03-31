local formatter = require("pr-description.formatter")
local config = require("pr-description.config")

---Helper: reset config to defaults, optionally applying overrides.
---@param opts? PrDescriptionConfig
local function reset_config(opts)
  config.setup(opts)
end

describe("formatter", function()
  before_each(function()
    reset_config()
  end)

  describe("add_summary_section", function()
    it("adds summary header and placeholder", function()
      local lines = {}
      formatter.add_summary_section(lines)
      assert.equals("## Summary", lines[1])
      assert.equals("", lines[2])
      assert.equals("_Brief description of changes_", lines[3])
      assert.equals("", lines[4])
    end)
  end)

  describe("add_category_sections", function()
    it("includes icons in titles by default", function()
      local lines = {}
      formatter.add_category_sections(lines, { features = { "- feat one" } })
      assert.equals("## ✨ Features", lines[1])
      assert.equals("- feat one", lines[2])
    end)

    it("omits icons when enable_icons is false", function()
      reset_config({ enable_icons = false })
      local lines = {}
      formatter.add_category_sections(lines, { features = { "- feat one" } })
      assert.equals("## Features", lines[1])
    end)

    it("skips empty categories", function()
      local lines = {}
      formatter.add_category_sections(lines, { features = {} })
      assert.equals(0, #lines)
    end)

    it("renders multiple categories in order", function()
      local lines = {}
      formatter.add_category_sections(lines, {
        fixes = { "- fix one" },
        features = { "- feat one" },
      })
      -- features comes before fixes in CATEGORY_SECTIONS order
      assert.equals("## ✨ Features", lines[1])
      assert.equals("- feat one", lines[2])
      assert.equals("## 🐛 Bug Fixes", lines[4])
      assert.equals("- fix one", lines[5])
    end)

    it("uses custom section titles when provided", function()
      reset_config({ sections = { features = "## New Stuff" } })
      local lines = {}
      formatter.add_category_sections(lines, { features = { "- feat one" } })
      assert.equals("## New Stuff", lines[1])
    end)
  end)

  describe("determine_file_group", function()
    it("groups src/ files by subdirectory", function()
      assert.equals("Components", formatter.determine_file_group("src/components/button.lua"))
    end)

    it("groups lib/ files by subdirectory", function()
      assert.equals("Utils", formatter.determine_file_group("lib/utils/helper.lua"))
    end)

    it("groups test files", function()
      assert.equals("Tests", formatter.determine_file_group("tests/foo_spec.lua"))
      assert.equals("Tests", formatter.determine_file_group("foo_test.lua"))
      assert.equals("Tests", formatter.determine_file_group("foo.test.js"))
      assert.equals("Tests", formatter.determine_file_group("foo_spec.lua"))
      assert.equals("Tests", formatter.determine_file_group("foo.spec.ts"))
      assert.equals("Tests", formatter.determine_file_group("spec/models/user_spec.rb"))
      assert.equals("Tests", formatter.determine_file_group("__tests__/App.test.js"))
    end)

    it("groups documentation files", function()
      assert.equals("Documentation", formatter.determine_file_group("docs/guide.md"))
      assert.equals("Documentation", formatter.determine_file_group("README.md"))
      assert.equals("Documentation", formatter.determine_file_group("CHANGELOG.md"))
    end)

    it("groups config files", function()
      assert.equals("Configuration", formatter.determine_file_group("config/settings.lua"))
      assert.equals("Configuration", formatter.determine_file_group("webpack.config.js"))
    end)

    it("groups by top-level directory", function()
      assert.equals("Plugin", formatter.determine_file_group("plugin/init.lua"))
    end)

    it("returns Root for top-level files", function()
      assert.equals("Root", formatter.determine_file_group("init.lua"))
    end)
  end)

  describe("group_files", function()
    it("includes status symbols when icons enabled", function()
      local file_list = { { path = "src/main/init.lua", status = "A" } }
      local file_stats = { ["src/main/init.lua"] = { insertions = 5, deletions = 0 } }
      local groups = formatter.group_files(file_list, file_stats)
      assert.equals(" ✨", groups["Main"][1].symbol)
    end)

    it("omits status symbols when icons disabled", function()
      reset_config({ enable_icons = false })
      local file_list = { { path = "src/main/init.lua", status = "A" } }
      local file_stats = { ["src/main/init.lua"] = { insertions = 5, deletions = 0 } }
      local groups = formatter.group_files(file_list, file_stats)
      assert.equals("", groups["Main"][1].symbol)
    end)

    it("formats stats with insertions and deletions", function()
      local file_list = { { path = "init.lua", status = "M" } }
      local file_stats = { ["init.lua"] = { insertions = 10, deletions = 5 } }
      local groups = formatter.group_files(file_list, file_stats)
      assert.equals(" (+10/-5)", groups["Root"][1].stats)
    end)

    it("formats stats with only insertions", function()
      local file_list = { { path = "init.lua", status = "A" } }
      local file_stats = { ["init.lua"] = { insertions = 3, deletions = 0 } }
      local groups = formatter.group_files(file_list, file_stats)
      assert.equals(" (+3)", groups["Root"][1].stats)
    end)

    it("formats stats with only deletions", function()
      local file_list = { { path = "init.lua", status = "D" } }
      local file_stats = { ["init.lua"] = { insertions = 0, deletions = 7 } }
      local groups = formatter.group_files(file_list, file_stats)
      assert.equals(" (-7)", groups["Root"][1].stats)
    end)

    it("returns empty stats when file has no stat entry", function()
      local file_list = { { path = "init.lua", status = "M" } }
      local groups = formatter.group_files(file_list, {})
      assert.equals("", groups["Root"][1].stats)
    end)

    it("uses empty string for unknown status", function()
      local file_list = { { path = "init.lua", status = "X" } }
      local groups = formatter.group_files(file_list, {})
      assert.equals("", groups["Root"][1].symbol)
    end)
  end)

  describe("sort_groups", function()
    it("sorts by predefined rank", function()
      local groups = {
        Tests = { {} },
        Root = { {} },
        Documentation = { {} },
      }
      local sorted = formatter.sort_groups(groups)
      assert.equals("Root", sorted[1])
      assert.equals("Tests", sorted[2])
      assert.equals("Documentation", sorted[3])
    end)

    it("sorts Configuration before Tests and Documentation", function()
      local groups = {
        Configuration = { {} },
        Tests = { {} },
        Documentation = { {} },
        Root = { {} },
      }
      local sorted = formatter.sort_groups(groups)
      assert.equals("Root", sorted[1])
      assert.equals("Configuration", sorted[2])
      assert.equals("Tests", sorted[3])
      assert.equals("Documentation", sorted[4])
    end)

    it("sorts unranked groups alphabetically between ranked ones", function()
      local groups = {
        Root = { {} },
        Zebra = { {} },
        Apple = { {} },
        Tests = { {} },
      }
      local sorted = formatter.sort_groups(groups)
      assert.equals("Root", sorted[1])
      assert.equals("Apple", sorted[2])
      assert.equals("Zebra", sorted[3])
      assert.equals("Tests", sorted[4])
    end)
  end)

  describe("add_file_changes_section", function()
    it("includes icon in header when icons enabled", function()
      local lines = {}
      local file_groups = { Root = { { path = "init.lua", symbol = " ✨", stats = " (+1)" } } }
      local file_stats = { ["init.lua"] = { insertions = 1, deletions = 0 } }
      formatter.add_file_changes_section(lines, file_groups, file_stats)
      assert.equals("## 📁 File Changes", lines[1])
    end)

    it("omits icon in header when icons disabled", function()
      reset_config({ enable_icons = false })
      local lines = {}
      local file_groups = { Root = { { path = "init.lua", symbol = "", stats = " (+1)" } } }
      local file_stats = { ["init.lua"] = { insertions = 1, deletions = 0 } }
      formatter.add_file_changes_section(lines, file_groups, file_stats)
      assert.equals("## File Changes", lines[1])
    end)

    it("does nothing for empty file groups", function()
      local lines = {}
      formatter.add_file_changes_section(lines, {}, {})
      assert.equals(0, #lines)
    end)

    it("renders group header with aggregated stats", function()
      local lines = {}
      local file_groups = {
        Root = {
          { path = "a.lua", symbol = "", stats = "" },
          { path = "b.lua", symbol = "", stats = "" },
        },
      }
      local file_stats = {
        ["a.lua"] = { insertions = 3, deletions = 1 },
        ["b.lua"] = { insertions = 2, deletions = 4 },
      }
      formatter.add_file_changes_section(lines, file_groups, file_stats)
      assert.equals("### Root (+5/-5 lines)", lines[3])
    end)

    it("renders file entries with stats and symbols", function()
      local lines = {}
      local file_groups = { Root = { { path = "a.lua", symbol = " ✨", stats = " (+3)" } } }
      local file_stats = { ["a.lua"] = { insertions = 3, deletions = 0 } }
      formatter.add_file_changes_section(lines, file_groups, file_stats)
      assert.equals("- `a.lua` (+3) ✨", lines[4])
    end)
  end)

  describe("add_footer", function()
    it("renders footer with stats", function()
      local lines = {}
      formatter.add_footer(lines, {
        total_files = 3,
        total_insertions = 20,
        total_deletions = 5,
        total_commits = 4,
        branch = "feat/icons",
        base_branch = "main",
      })
      assert.equals("---", lines[1])
      assert.equals("**Changes:** 3 files, +20 insertions, -5 deletions", lines[3])
      assert.equals("**Commits:** 4", lines[4])
      assert.equals("**Branch:** `feat/icons`", lines[5])
      assert.equals("**Base:** `main`", lines[6])
    end)
  end)

  describe("generate", function()
    local default_stats = {
      total_files = 1,
      total_insertions = 1,
      total_deletions = 0,
      total_commits = 1,
      branch = "feat/test",
      base_branch = "main",
    }

    it("produces a complete description with icons", function()
      local result = formatter.generate(
        { features = { "- feat one" } },
        { Root = { { path = "a.lua", symbol = " ✨", stats = " (+1)" } } },
        { ["a.lua"] = { insertions = 1, deletions = 0 } },
        default_stats
      )
      assert.truthy(result:find("Features"))
      assert.truthy(result:find("✨"))
      assert.truthy(result:find("File Changes"))
      assert.truthy(result:find("📁"))
      assert.truthy(result:find("## Summary", 1, true))
      assert.truthy(result:find("**Branch:** `feat/test`", 1, true))
    end)

    it("produces a complete description without icons", function()
      reset_config({ enable_icons = false })
      local result = formatter.generate(
        { features = { "- feat one" } },
        { Root = { { path = "a.lua", symbol = "", stats = " (+1)" } } },
        { ["a.lua"] = { insertions = 1, deletions = 0 } },
        default_stats
      )
      assert.truthy(result:find("## Features", 1, true))
      assert.falsy(result:find("✨", 1, true))
      assert.truthy(result:find("## File Changes", 1, true))
      assert.falsy(result:find("📁", 1, true))
    end)

    it("includes stats footer by default", function()
      local result = formatter.generate(
        { features = { "- feat one" } },
        { Root = { { path = "a.lua", symbol = " ✨", stats = " (+1)" } } },
        { ["a.lua"] = { insertions = 1, deletions = 0 } },
        default_stats
      )
      assert.truthy(result:find("**Changes:**", 1, true))
      assert.truthy(result:find("**Commits:**", 1, true))
      assert.truthy(result:find("**Branch:** `feat/test`", 1, true))
      assert.truthy(result:find("**Base:** `main`", 1, true))
    end)

    it("omits stats footer when enable_stats_footer is false", function()
      reset_config({ enable_stats_footer = false })
      local result = formatter.generate(
        { features = { "- feat one" } },
        { Root = { { path = "a.lua", symbol = " ✨", stats = " (+1)" } } },
        { ["a.lua"] = { insertions = 1, deletions = 0 } },
        default_stats
      )
      assert.falsy(result:find("**Changes:**", 1, true))
      assert.falsy(result:find("**Commits:**", 1, true))
      assert.falsy(result:find("**Branch:**", 1, true))
      assert.falsy(result:find("**Base:**", 1, true))
    end)
  end)
end)
