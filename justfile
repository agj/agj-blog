
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

# Check for errors.
review: install
    pnpm exec elm-review --compiler ./node_modules/.bin/lamdera

# Check for errors, and automatically fix them.
review-fix: install
    pnpm exec elm-review --compiler ./node_modules/.bin/lamdera --fix-all

[private]
install:
    pnpm install
