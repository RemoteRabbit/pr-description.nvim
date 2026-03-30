stds.nvim = {
  globals = {
    "vim",
    "describe", "it", "before_each", "after_each",
  },
  read_globals = {
    "jit", "os", "debug", "package", "assert",
  }
}

std = "lua51+nvim"
cache = true
codes = true

ignore = {
  "212/_.*",
  "214",
  "631",
}

include_files = {
  "lua/**/*.lua",
  "plugin/**/*.lua",
  "tests/**/*.lua",
}
