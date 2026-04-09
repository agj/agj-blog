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
  print $"- Message: ($error.message)"
  print $"  In file: ($error.filename)"
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

let languageTagMatching = [
  { language: "spa", tag: "espanol" }
  { language: "jpn", tag: "nihongo" }
]

let errors = $posts
  | each {|post|
      $languageTagMatching
        | each {|lm|
          let $isLanguage = $post.frontmatter.language | $in == $lm.language or $lm.language in $in
          let $hasLanguageTag = $lm.tag in $post.frontmatter.tags

          let languageTagMessages = [
              (if ($isLanguage and not $hasLanguageTag) { $"`($lm.language)` language post without `($lm.tag)` tag." }),
              (if (not $isLanguage and $hasLanguageTag) { $"Post has `($lm.tag)` tag but isn't `($lm.language)` language." }),
            ]
            | where { $in != null }
          let imageUrlMessages = $post.imageUrls
            | where {|imageUrl| not ($"..($imageUrl)" | path exists) }
            | each {|imageUrl| $"Image path doesn't exist: ($imageUrl)" }
          let messages = $languageTagMessages | append $imageUrlMessages

          $messages | each {|msg| { filename: $post.filename, message: $msg } }
        }
        | flatten
    }
  | flatten

if ($errors | length) > 0 {
  print "❌ Summary of errors:\n"
  $errors | each { $in | printError }
  null
} else {
  print "✅ All posts okay!"
}
