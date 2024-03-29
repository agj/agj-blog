
init: ## Load the dependencies.
	@echo "You may type 'exit' to return to the regular shell.\n"
	nix develop -c "$$SHELL"

dev: ## Run development server.
	elm-pages dev

build: ## Build for release.
	elm-pages build



# The following makes this file self-documenting.
# See: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
