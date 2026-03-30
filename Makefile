.PHONY: test lint format check

PLENARY_DIR ?= /tmp/plenary.nvim

test: $(PLENARY_DIR)
	@nvim --headless --noplugin \
		-u tests/minimal_init.lua \
		-c "set runtimepath+=$(PLENARY_DIR)" \
		-c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })"

$(PLENARY_DIR):
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR)

lint:
	@luacheck lua/ plugin/ tests/ --config .luacheckrc

format:
	@stylua --config-path stylua.toml lua/ plugin/ tests/

check: lint
	@stylua --config-path stylua.toml --check lua/ plugin/ tests/
