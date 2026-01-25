use shared.nu *

print "🔍 Checking errors in posts…\n"

let posts = glob "data/posts/**/*.md"
  | each {|filename|
    let frontmatter = open $filename | getFrontmatter
    { filename: $filename, frontmatter: $frontmatter }
  }

let errors = $posts
  | each {|post|
      let $isSpanish = $post.frontmatter.language | $in == "spa" or "spa" in $in
      let $hasSpanishTag = "espanol" in $post.frontmatter.tags

      if ($isSpanish and not $hasSpanishTag) {
        $"Spanish language without `spanish` tag: ($post.filename)"
      } else if (not $isSpanish and $hasSpanishTag) {
        $"Has `spanish` tag but isn't Spanish language: ($post.filename)"
      }
    }
  | flatten

if ($errors | length) > 0 {
  print "❌ Summary of errors:\n"
  print ($errors | str join "\n")
} else {
  print "✅ All posts okay!"
}
