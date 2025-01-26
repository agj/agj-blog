
[private]
default:
    just --list

# Load the dependencies.
init:
    @echo "You may type 'exit' to return to the regular shell.\n"
    nix develop -c "$$SHELL"

# Run development server.
dev: install
    pnpm run start

# Build for release.
build: install
    pnpm run build

[private]
install:
    pnpm install
