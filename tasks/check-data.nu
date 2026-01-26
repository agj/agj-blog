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

def printError []: record<filename: string, message: string> -> nothing {
  let error = $in
  print $"- In file: ($error.filename)"
  print $"  Message: ($error.message)"
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

      let messages = [
          (if ($isSpanish and not $hasSpanishTag) { $"Spanish language without `spanish` tag." }),
          (if (not $isSpanish and $hasSpanishTag) { $"Has `spanish` tag but isn't Spanish language." }),
        ] | where { $in != null }

      $messages | each {|msg| { filename: $post.filename, message: $msg } }
    }
  | flatten

if ($errors | length) > 0 {
  print "❌ Summary of errors:\n"
  $errors | each { $in | printError }
} else {
  print "✅ All posts okay!"
}
