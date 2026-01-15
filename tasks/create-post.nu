use shared.nu *

let title = "Temporary title"

let date = date now | date to-timezone 'UTC'
let year = $date | format date '%Y'
let month = $date | format date '%m'
let titleSlug = $title | str trim | str downcase | str kebab-case | remove-diacritics $in

let directory = $"data/posts/($year)"
let filename = $"($directory)/($month)-($titleSlug).md"
let frontmatter = {
  title: $title
  date: ($date | formatPostDate)
  categories: ["add-categories-here"]
  tags: ["add-tags-here"]
  language: eng
}

let body = $"---\n($frontmatter | toYaml)\n---\n\nPost content.\n"

mkdir $directory
$body | save $filename

# Format the new file.
prettier --write $filename
