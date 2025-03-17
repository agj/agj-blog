lamdera := "./node_modules/.bin/lamdera"

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

# Run `dev` and `review-watch` in parallel.
dev-review: install
    mprocs

# Check for errors.
review: install
    pnpm exec elm-review --compiler {{lamdera}}

# Check for errors, and automatically fix them.
review-fix: install
    pnpm exec elm-review --compiler {{lamdera}} --fix

# Check for errors, and listen for changes in files.
review-watch: install
    pnpm exec elm-review --compiler {{lamdera}} --watch --fix

[private]
install:
    pnpm install
