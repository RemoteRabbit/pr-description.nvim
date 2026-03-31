#!/usr/bin/env lua
--- Generates the Configuration code block in README.md from config.lua

local script_dir = arg[0]:match("(.*/)")
local repo_root = script_dir .. "../"
local config_path = repo_root .. "lua/pr-description/config.lua"
local readme_path = repo_root .. "README.md"

local START_MARKER = "<!-- CONFIG_START -->"
local END_MARKER = "<!-- CONFIG_END -->"

-- Read file contents
local function read_file(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*a")
  f:close()
  return content
end

local function write_file(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

-- Parse @field annotations for descriptions (line by line)
local function parse_field_comments(source)
  local comments = {}
  for line in source:gmatch("[^\n]+") do
    -- Match: ---@field name? type(s) description text
    -- The type can contain spaces (e.g., table<string, string>)
    local name, rest = line:match("^%-%-%-@field%s+([a-z_]+)%?%s+(.*)")
    if name and rest then
      -- Skip the type token(s): walk past the type which may include <...>
      local desc
      if rest:match("^%S*<") then
        -- Type with generics like table<string, string>
        desc = rest:match("^%S*<[^>]+>%s+(.*)")
      else
        -- Simple type like boolean, number, string
        desc = rest:match("^%S+%s+(.*)")
      end
      if desc then
        comments[name] = desc:match("^(.-)%s*$")
      end
    end
  end
  return comments
end

-- Parse M.defaults table for keys and values (line by line)
local function parse_defaults(source)
  local defaults = {}
  local in_defaults = false
  for line in source:gmatch("[^\n]+") do
    if line:match("^M%.defaults") then
      in_defaults = true
    elseif in_defaults then
      if line:match("^}") then
        break
      end
      local key, value = line:match("^%s+([a-z_]+)%s*=%s*(.+),%s*$")
      if key then
        table.insert(defaults, { key = key, value = value })
      end
    end
  end
  if #defaults == 0 then
    error("Could not find M.defaults table in config.lua")
  end
  return defaults
end

-- Build the config code block
local function build_config_block(defaults, comments)
  local lines = { 'require("pr-description").setup({' }
  for i, entry in ipairs(defaults) do
    local comment = comments[entry.key]
    if comment then
      table.insert(lines, "  -- " .. comment)
    end
    table.insert(lines, "  " .. entry.key .. " = " .. entry.value .. ",")
    if i < #defaults then
      table.insert(lines, "")
    end
  end
  table.insert(lines, "})")
  return table.concat(lines, "\n")
end

-- Main
local config_source = read_file(config_path)
local comments = parse_field_comments(config_source)
local defaults = parse_defaults(config_source)
local config_block = build_config_block(defaults, comments)

local readme = read_file(readme_path)

if not readme:find(START_MARKER, 1, true) then
  io.stderr:write("Error: " .. START_MARKER .. " not found in README.md\n")
  os.exit(1)
end

local replacement = START_MARKER .. "\n```lua\n" .. config_block .. "\n```\n" .. END_MARKER

-- Match across newlines by finding marker positions directly
local start_pos = readme:find(START_MARKER, 1, true)
local end_pos = readme:find(END_MARKER, start_pos, true)
local new_readme = readme:sub(1, start_pos - 1) .. replacement .. readme:sub(end_pos + #END_MARKER)

if new_readme == readme then
  print("README.md config section is up to date")
  os.exit(0)
end

write_file(readme_path, new_readme)
print("README.md config section updated")
