# Source data.
let sourceFilename = ls --all data/posts/**/*.md | sort-by --reverse modified | get 0.name
let postData = $sourceFilename | open
let postLines = $postData | split row "\n" | split list "---"
let frontmatter = $postLines | get 1 | str join "\n" | from yaml

export def remove-diacritics [text: string] {
  let diacritics_map = {
    "á": "a",
    "é": "e",
    "í": "i",
    "ó": "o",
    "ú": "u",
    "ü": "u",
  }
  $text
  | split chars
  | each {|char| $diacritics_map | get --optional $char | default $char }
  | str join ''
}

# Update the post's slug and path.
let date = date now | date to-timezone 'UTC'
let year = $date | format date '%Y'
let month = $date | format date '%m'
let titleSlug = $frontmatter.title | str trim | str downcase | str kebab-case | remove-diacritics $in
let updatedFilename = $"data/posts/($year)/($month)-($titleSlug).md"

# Update the date in the frontmatter.
let updatedDate = $date | format date '%Y-%m-%d %H:%M:00'
let updatedFrontmatter = $frontmatter | update date $updatedDate
let updatedFrontmatterLines = $updatedFrontmatter | to yaml | split row "\n"

let updatedPostLines = $postLines.0 ++ ["---"] ++ $updatedFrontmatterLines ++ ["---"] ++ ($postLines | skip 2 | flatten)

# Save the updated post data in its new path.
$updatedPostLines | str join "\n" | save --force $updatedFilename

# Delete the old file.
if ($sourceFilename != $updatedFilename) {
  rm $sourceFilename
}

# Format the new file.
prettier --write $updatedFilename

