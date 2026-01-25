use shared.nu *

print "🔍 Checking errors in posts…\n"

def findImages [] {
  let cur = $in
  let type = $cur | describe

  if $type =~ '^list|^table' {
    $cur | each {|c| $c | findImages }
  } else if $type =~ "^record" {
    let tag = $cur.tag

    if ($tag == "image") {
      [$cur]
    } else {
      $cur.content | findImages | flatten
    }
  } else {
    []
  }
}

let posts = glob "data/posts/**/*.md"
  | each {|filename|
    let file = open $filename
    let frontmatter = $file | getFrontmatter
    let content = $file | cmark --to xml | from xml --allow-dtd | get content
    let images = $content | findImages | flatten
    let imageUrls = $images.attributes.destination

    { filename: $filename, frontmatter: $frontmatter, imageUrls: $imageUrls }
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
