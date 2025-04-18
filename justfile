lamdera := "./node_modules/.bin/lamdera"

[private]
@default:
    just --list --unsorted

# Load the dependencies.
init:
    @echo "You may type 'exit' to return to the regular shell.\n"
    nix develop -c "$$SHELL"

# Run development server.
dev: install
    pnpm run start

# Run `dev` and `review-watch` in parallel.
dev-review: install
    mprocs

# Build for release.
build: install
    pnpm run build

# Deploy built files.
deploy:
    nu ./tasks/deploy.nu

# Maintenance

# Check for errors.
[group('maintenance')]
review: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}}

# Check for errors, and automatically fix them.
[group('maintenance')]
review-fix: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --fix

# Check for errors, and listen for changes in files.
[group('maintenance')]
review-watch: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --watch --fix

# Suppress remaining review errors.
[group('maintenance')]
review-suppress: install
    pnpm exec elm-review suppress ./src ./app --compiler {{lamdera}}

# Resurface suppressed review errors.
[group('maintenance')]
review-unsuppress: install
    pnpm exec elm-review ./src ./app --compiler {{lamdera}} --unsuppress

# Format files.
[group('maintenance')]
format:
    prettier --write '**/*.{js,ts,md,css,scss}'

# Other

# Removes generated and downloaded data.
[group('other')]
clean:
    rm -rf dist .elm-pages gen functions elm-stuff node_modules

# Writes a snapshot of settings as a Git stash.
[group('other')]
save-settings:
    #!/usr/bin/env nu
    let gitStageChanges = git diff --cached
    if $gitStageChanges != "" {
        print "🛑 Git stage is dirty! Make sure it's clean before running this task."
        exit 1
    }

    let today = date now | format date "%Y-%m-%d"
    [".helix/*", ".env"] | each { git add -f $in }
    git stash -m $"⚙️ settings ($today)"
    git stash apply
    git reset

# Internal

[private]
install:
    pnpm install
