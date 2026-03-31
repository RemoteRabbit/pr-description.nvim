local links = require("pr-description.links")

describe("links", function()
  describe("parse_remote_url", function()
    it("parses SSH URLs", function()
      local host, path = links.parse_remote_url("git@github.com:user/repo.git")
      assert.equals("github.com", host)
      assert.equals("user/repo", path)
    end)

    it("parses HTTPS URLs", function()
      local host, path = links.parse_remote_url("https://github.com/user/repo.git")
      assert.equals("github.com", host)
      assert.equals("user/repo", path)
    end)

    it("strips .git suffix", function()
      local _, path = links.parse_remote_url("git@github.com:user/repo.git")
      assert.equals("user/repo", path)
    end)

    it("handles URLs without .git suffix", function()
      local _, path = links.parse_remote_url("https://github.com/user/repo")
      assert.equals("user/repo", path)
    end)

    it("parses ssh:// URLs", function()
      local host, path = links.parse_remote_url("ssh://git@github.com/user/repo.git")
      assert.equals("github.com", host)
      assert.equals("user/repo", path)
    end)

    it("returns nil for unrecognized URLs", function()
      local host, path = links.parse_remote_url("not-a-url")
      assert.is_nil(host)
      assert.is_nil(path)
    end)
  end)

  describe("build_repo_url", function()
    it("builds HTTPS URL from host and path", function()
      assert.equals("https://github.com/user/repo", links.build_repo_url("github.com", "user/repo"))
    end)

    it("returns empty string for nil inputs", function()
      assert.equals("", links.build_repo_url(nil, nil))
    end)
  end)

  describe("is_gitlab_host", function()
    it("detects GitLab hosts", function()
      assert.is_true(links.is_gitlab_host("gitlab.com"))
      assert.is_true(links.is_gitlab_host("gitlab.company.com"))
    end)

    it("returns false for non-GitLab hosts", function()
      assert.is_falsy(links.is_gitlab_host("github.com"))
    end)

    it("handles nil", function()
      assert.is_falsy(links.is_gitlab_host(nil))
    end)
  end)

  describe("add_issue_links", function()
    it("links fix references on GitHub", function()
      local result = links.add_issue_links("fixes #42", "https://github.com/user/repo", false)
      assert.equals("fixes [#42](https://github.com/user/repo/issues/42)", result)
    end)

    it("links fix references on GitLab", function()
      local result = links.add_issue_links("fixes #42", "https://gitlab.com/user/repo", true)
      assert.equals("fixes [#42](https://gitlab.com/user/repo/-/issues/42)", result)
    end)

    it("links capitalized keywords", function()
      local result = links.add_issue_links("Fixes #42", "https://github.com/user/repo", false)
      assert.equals("Fixes [#42](https://github.com/user/repo/issues/42)", result)
    end)

    it("links Closes keyword", function()
      local result = links.add_issue_links("Closes #10", "https://github.com/user/repo", false)
      assert.equals("Closes [#10](https://github.com/user/repo/issues/10)", result)
    end)

    it("links Resolves keyword", function()
      local result = links.add_issue_links("Resolves #7", "https://github.com/user/repo", false)
      assert.equals("Resolves [#7](https://github.com/user/repo/issues/7)", result)
    end)

    it("skips linking when no repo URL", function()
      assert.equals("fixes #42", links.add_issue_links("fixes #42", "", false))
    end)
  end)

  describe("add_jira_links", function()
    it("links Jira tickets when base_url provided", function()
      local result = links.add_jira_links("PROJ-123 fix", "https://company.atlassian.net/browse")
      assert.equals("[PROJ-123](https://company.atlassian.net/browse/PROJ-123) fix", result)
    end)

    it("skips linking when no base_url", function()
      assert.equals("PROJ-123 fix", links.add_jira_links("PROJ-123 fix", nil))
    end)
  end)

  describe("add_all_links", function()
    it("links both issues and Jira tickets", function()
      local result = links.add_all_links(
        "fixes #42 for PROJ-123",
        "https://github.com/user/repo",
        false,
        "https://company.atlassian.net/browse"
      )
      assert.truthy(result:find("%[#42%]%(https://github.com/user/repo/issues/42%)"))
      assert.truthy(result:find("%[PROJ%-123%]%(https://company.atlassian.net/browse/PROJ%-123%)"))
    end)

    it("works without Jira base URL", function()
      local result = links.add_all_links("fixes #42", "https://github.com/user/repo", false, nil)
      assert.truthy(result:find("%[#42%]"))
    end)
  end)

  describe("make_commit_link", function()
    it("creates GitHub commit link", function()
      local result = links.make_commit_link("abc1234", "https://github.com/user/repo", false)
      assert.equals(" [`abc1234`](https://github.com/user/repo/commit/abc1234)", result)
    end)

    it("creates GitLab commit link", function()
      local result = links.make_commit_link("abc1234", "https://gitlab.com/user/repo", true)
      assert.equals(" [`abc1234`](https://gitlab.com/user/repo/-/commit/abc1234)", result)
    end)

    it("returns empty string when repo_url is empty", function()
      local result = links.make_commit_link("abc1234", "", false)
      assert.equals("", result)
    end)
  end)
end)
