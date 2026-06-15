#!/usr/bin/env lua
--- Generates doc/api/README.md from the LuaCATS annotations in lua/pr-description/*.lua

local script_dir = arg[0]:match("(.*/)") or "./"
local repo_root = script_dir .. "../"
local src_dir = repo_root .. "lua/pr-description/"
local out_path = repo_root .. "doc/api/README.md"

-- Modules in the order they should appear in the docs.
local MODULE_ORDER = { "init", "config", "git", "parser", "links", "formatter" }

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

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Strip the leading "---" (and at most one following space) from an annotation line.
local function strip_comment(line)
  local body = line:match("^%s*%-%-%-?(.*)$")
  if body == nil then
    return nil
  end
  return (body:gsub("^ ", ""))
end

-- Split a "<type> <description>" string into type and description, where the
-- type may contain balanced <...> or (...) (e.g. table<string, FileStats>).
local function split_type_desc(s)
  local depth = 0
  local prev = ""
  for k = 1, #s do
    local c = s:sub(k, k)
    if c == "<" or c == "(" then
      depth = depth + 1
    elseif c == ">" or c == ")" then
      depth = depth - 1
    elseif c == " " and depth == 0 and prev ~= ":" then
      -- a depth-0 space ends the type, unless it directly follows a ":"
      -- (e.g. the return part of `fun(x: string): string`)
      return s:sub(1, k - 1), trim(s:sub(k + 1))
    end
    if c ~= " " then
      prev = c
    end
  end
  return s, ""
end

-- Read a source file into a list of "blocks". Each block is either:
--   { kind = "comment", lines = {stripped...}, attached = "<fn signature>" | nil }
-- A comment block is "attached" when the line immediately after it is a
-- `function M.name(...)` declaration.
local function parse_blocks(source)
  local lines = {}
  for line in (source .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, line)
  end

  local blocks = {}
  local current = nil

  local function flush(next_line)
    if not current then
      return
    end
    local fn_name, fn_args = (next_line or ""):match("^function%s+M%.([%w_]+)%s*(%b())")
    if fn_name then
      current.attached = "M." .. fn_name .. fn_args
    end
    table.insert(blocks, current)
    current = nil
  end

  for _, line in ipairs(lines) do
    if line:match("^%s*%-%-%-") then
      current = current or { kind = "comment", lines = {} }
      table.insert(current.lines, strip_comment(line))
    else
      flush(line)
    end
  end
  flush(nil)

  return blocks
end

-- Extract the module @brief prose (text between `@brief [[` and `@brief ]]`).
local function extract_brief(blocks)
  for _, block in ipairs(blocks) do
    local capturing = false
    local out = {}
    for _, l in ipairs(block.lines) do
      if l:match("^@brief%s*%[%[") then
        capturing = true
      elseif l:match("^@brief%s*%]%]") then
        capturing = false
      elseif capturing then
        table.insert(out, l)
      end
    end
    if #out > 0 then
      -- drop leading/trailing blank lines
      while out[1] == "" do
        table.remove(out, 1)
      end
      while out[#out] == "" do
        table.remove(out)
      end
      return table.concat(out, "\n")
    end
  end
  return nil
end

-- Render a function block (a comment block with `attached` signature).
local function render_function(block, out)
  table.insert(out, "### `" .. block.attached .. "`")
  table.insert(out, "")

  local prose, params, returns = {}, {}, {}
  for _, l in ipairs(block.lines) do
    local param = l:match("^@param%s+(.*)$")
    local ret = l:match("^@return%s+(.*)$")
    if param then
      local name, rest = param:match("^(%S+)%s*(.*)$")
      local ptype, desc = split_type_desc(rest)
      table.insert(params, { name = name, type = ptype, desc = desc })
    elseif ret then
      local rtype, desc = split_type_desc(ret)
      table.insert(returns, { type = rtype, desc = desc })
    elseif l:match("^@") then
      -- ignore other annotations (@class, @type, etc.) inside function docs
    else
      table.insert(prose, l)
    end
  end

  while prose[1] == "" do
    table.remove(prose, 1)
  end
  while prose[#prose] == "" do
    table.remove(prose)
  end
  if #prose > 0 then
    table.insert(out, table.concat(prose, "\n"))
    table.insert(out, "")
  end

  if #params > 0 then
    table.insert(out, "**Parameters:**")
    table.insert(out, "")
    for _, p in ipairs(params) do
      local line = "- `" .. p.name .. "` (`" .. p.type .. "`)"
      if p.desc and p.desc ~= "" then
        line = line .. " — " .. p.desc
      end
      table.insert(out, line)
    end
    table.insert(out, "")
  end

  if #returns > 0 then
    table.insert(out, "**Returns:**")
    table.insert(out, "")
    for _, r in ipairs(returns) do
      local line = "- `" .. r.type .. "`"
      if r.desc and r.desc ~= "" then
        line = line .. " — " .. r.desc
      end
      table.insert(out, line)
    end
    table.insert(out, "")
  end
end

-- Render a standalone `@class` block as a type definition.
local function render_class(block, out)
  local name
  local desc = {}
  local fields = {}
  for _, l in ipairs(block.lines) do
    local cls = l:match("^@class%s+([%w_]+)")
    local field = l:match("^@field%s+(.*)$")
    if cls then
      name = cls
    elseif field then
      local fname, rest = field:match("^(%S+)%s*(.*)$")
      local ftype, fdesc = split_type_desc(rest)
      table.insert(fields, { name = fname, type = ftype, desc = fdesc })
    elseif not l:match("^@") and l ~= "" then
      table.insert(desc, l)
    end
  end
  if not name then
    return false
  end

  table.insert(out, "### Type: `" .. name .. "`")
  table.insert(out, "")
  if #desc > 0 then
    table.insert(out, table.concat(desc, "\n"))
    table.insert(out, "")
  end
  for _, f in ipairs(fields) do
    local line = "- `" .. f.name .. "` (`" .. f.type .. "`)"
    if f.desc and f.desc ~= "" then
      line = line .. " — " .. f.desc
    end
    table.insert(out, line)
  end
  table.insert(out, "")
  return true
end

local function render_module(module, out)
  local source = read_file(src_dir .. module .. ".lua")
  local blocks = parse_blocks(source)

  table.insert(out, "## pr-description." .. module)
  table.insert(out, "")

  local brief = extract_brief(blocks)
  if brief then
    table.insert(out, brief)
    table.insert(out, "")
  end

  for _, block in ipairs(blocks) do
    if block.attached then
      render_function(block, out)
    else
      local has_class = false
      for _, l in ipairs(block.lines) do
        if l:match("^@class%s") then
          has_class = true
          break
        end
      end
      if has_class then
        render_class(block, out)
      end
    end
  end
end

-- Main
local out = {
  "# API Reference",
  "",
  "Auto-generated from LuaCATS annotations. Do not edit by hand;",
  "run `make docs` to regenerate.",
  "",
}

for _, module in ipairs(MODULE_ORDER) do
  if file_exists(src_dir .. module .. ".lua") then
    render_module(module, out)
  end
end

-- Trim trailing blank lines and ensure a single trailing newline.
while out[#out] == "" do
  table.remove(out)
end
local content = table.concat(out, "\n") .. "\n"

local existing = file_exists(out_path) and read_file(out_path) or nil
if existing == content then
  print("doc/api/README.md is up to date")
  os.exit(0)
end

write_file(out_path, content)
print("doc/api/README.md updated")
