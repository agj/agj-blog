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

# Deploy built files.
deploy:
    nu ./tasks/deploy.nu

# Run `dev` and `review-watch` in parallel.
dev-review: install
    mprocs

# Check for errors.
review: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}}

# Check for errors, and automatically fix them.
review-fix: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --fix

# Check for errors, and listen for changes in files.
review-watch: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --watch --fix

# Suppress remaining review errors.
review-suppress: install
    pnpm exec elm-review suppress ./src ./app --compiler {{lamdera}}

# Resurface suppressed review errors.
review-unsuppress: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --unsuppress

# Format files.
format:
    prettier --write '**/*.{js,ts,md,css,scss}'

# Removes generated and downloaded data.
clean:
    rm -rf dist .elm-pages gen functions elm-stuff node_modules

# Writes a snapshot of settings as a Git stash.
save-settings:
    #!/usr/bin/env nu
    let gitStageChanges = git diff --cached
    if $gitStageChanges != "" {
        print "🛑 Git stage is dirty! Make sure it's clean before running this task."
        exit 1
    }

    [".helix/*", ".env"] | each { git add -f $in }
    git stash -m '⚙️ settings'
    git stash apply
    git reset

[private]
install:
    pnpm install
