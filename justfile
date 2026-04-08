# DragonLoot development tasks

# List available recipes
default:
    @just --list

# Run busted test suite
test:
    mise run test

# Run luacheck linter
lint:
    mise run lint

# Format Lua files with StyLua
fmt:
    stylua DragonLoot/ DragonLoot_Options/ spec/

# Format check only (no writes)
fmt-check:
    stylua --check DragonLoot/ DragonLoot_Options/ spec/

# Run lint and tests
check: lint test
