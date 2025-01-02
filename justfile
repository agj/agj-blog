
[private]
default:
    just --list

# Load the dependencies.
init:
    @echo "You may type 'exit' to return to the regular shell.\n"
    nix develop -c "$$SHELL"

# Run development server.
dev: install
    pnpm exec elm-pages dev

# Build for release.
build: install
    pnpm exec elm-pages build

[private]
install:
    pnpm install
