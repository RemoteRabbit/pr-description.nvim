.PHONY: test lint format check docs

PLENARY_DIR ?= /tmp/plenary.nvim

test: $(PLENARY_DIR)
	@nvim --headless --noplugin \
		-u tests/minimal_init.lua \
		-c "set runtimepath+=$(PLENARY_DIR)" \
		-c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })"

$(PLENARY_DIR):
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR)

lint:
	@lua5.4 -e 'package.path="$(HOME)/.luarocks/share/lua/5.4/?.lua;$(HOME)/.luarocks/share/lua/5.4/?/init.lua;"..package.path;package.cpath="$(HOME)/.luarocks/lib/lua/5.4/?.so;/usr/lib/lua/5.4/?.so;"..package.cpath' $(HOME)/.luarocks/lib/luarocks/rocks-5.4/luacheck/1.2.0-1/bin/luacheck lua/ plugin/ tests/ --config .luacheckrc

format:
	@stylua --config-path stylua.toml lua/ plugin/ tests/

check: lint
	@stylua --config-path stylua.toml --check lua/ plugin/ tests/

docs:
	@lua scripts/update-readme-config.lua
