# Contributing to pr-description.nvim

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/remoterabbit/pr-description.nvim.git
   cd pr-description.nvim
   ```

2. **Install dependencies**

   - [Neovim](https://neovim.io/) >= 0.9.0
   - [StyLua](https://github.com/JohnnyMorganz/StyLua) for formatting
   - [Luacheck](https://github.com/luarocks/luacheck) for linting
   - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for tests (cloned automatically in CI)

3. **Set up pre-commit hooks**

   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

## Making Changes

1. Fork the repo and create a feature branch from `main`:

   ```bash
   git checkout -b feat/my-feature
   ```

2. Follow [conventional commits](https://www.conventionalcommits.org/) for all commit messages:

   - `feat:` — new feature
   - `fix:` — bug fix
   - `docs:` — documentation only
   - `refactor:` — code refactoring
   - `test:` — adding or updating tests
   - `chore:` — maintenance tasks

3. Keep changes focused — one feature or fix per PR.

## Code Style

- **Formatting**: Run `make format` or let pre-commit handle it. We use StyLua with 2-space indentation and 120-column width.
- **Linting**: Run `make lint` to check for issues.
- **Annotations**: Use [LuaCATS](https://luals.github.io/wiki/annotations/) type annotations on all public functions.
- **Conventions**: Follow existing patterns in the codebase. Look at neighboring code before adding new code.

## Running Tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted-style test harness.

```bash
# Clone plenary if you don't have it
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim /tmp/plenary.nvim

# Run all tests
make test

# Or run manually
nvim --headless --noplugin \
  -u tests/minimal_init.lua \
  -c "set runtimepath+=/tmp/plenary.nvim" \
  -c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })"
```

## Adding Tests

- Place test files in `tests/` with a `_spec.lua` suffix.
- Test pure functions (parser, links, formatter) directly.
- For git-dependent functionality, document manual testing steps in your PR.

## Checklist Before Submitting

- [ ] Code is formatted (`make format`)
- [ ] Linting passes (`make lint`)
- [ ] Tests pass (`make test`)
- [ ] New public functions have LuaCATS annotations
- [ ] Commit messages follow conventional commits
- [ ] PR description explains the change

## Reporting Issues

When filing an issue, please include:

- Neovim version (`nvim --version`)
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages (`:messages`)

## License

By contributing, you agree that your contributions will be released into the public domain under the [Unlicense](https://unlicense.org).
