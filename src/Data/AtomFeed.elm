module Data.AtomFeed exposing (..)

import Custom.Markdown
import Data.Category as Category exposing (Category)
import Data.Post as Post exposing (Post)
import Rfc3339
import Time


{-| Atom XML feed generated according to
[this specification](https://validator.w3.org/feed/docs/atom.html).
-}
generate :
    { title : String
    , url : String
    , description : String
    , atomFeedUrl : String
    }
    -> List Post
    -> String
generate config posts =
    let
        orderedPosts =
            posts
                |> List.sortBy (\post -> Time.posixToMillis post.gist.dateTime)
                |> List.reverse
    in
    """<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>{url}</id>
  <updated>{updated}</updated>
  <link href="{url}" />
  <title><![CDATA[{title}]]></title>
  <author>
    <name>agj</name>
  </author>
  <link rel="self" type="application/atom+xml" href="{atomFeedUrl}" />
{entries}
</feed>
    """
        |> String.replace "{title}" config.title
        |> String.replace "{url}" (ensureEndsInSlash config.url)
        |> String.replace "{updated}"
            (orderedPosts
                |> List.head
                |> Maybe.map (\post -> post.gist.dateTime)
                |> Maybe.withDefault (Time.millisToPosix 0)
                |> posixToRfc3339
            )
        |> String.replace "{atomFeedUrl}" config.atomFeedUrl
        |> String.replace "{entries}"
            (orderedPosts
                |> List.map
                    (\post ->
                        generateEntry
                            { title = post.gist.title
                            , url = Post.gistToCanonicalUrl post.gist
                            , summary = Custom.Markdown.getSummary post.markdown
                            , published = post.gist.dateTime
                            , categories = post.gist.categories
                            }
                    )
                |> String.join ""
            )



-- INTERNAL


generateEntry :
    { title : String
    , url : String
    , summary : String
    , published : Time.Posix
    , categories : List Category
    }
    -> String
generateEntry c =
    """
  <entry>
    <id>{url}</id>
    <published>{published}</published>
    <updated>{updated}</updated>
    <link href="{url}" />
    <title><![CDATA[{title}]]></title>
    <summary><![CDATA[{summary}]]></summary>
    {categories}
  </entry>
    """
        |> String.replace "{title}" c.title
        |> String.replace "{url}" c.url
        |> String.replace "{published}" (posixToRfc3339 c.published)
        |> String.replace "{updated}" (posixToRfc3339 c.published)
        |> String.replace "{summary}" c.summary
        |> String.replace "{categories}"
            (List.map generateCategory c.categories
                |> String.join " "
            )


generateCategory : Category -> String
generateCategory category =
    """<category term="{slug}" label="{name}" />"""
        |> String.replace "{slug}" (Category.getSlug category)
        |> String.replace "{name}" (Category.getName category)


posixToRfc3339 : Time.Posix -> String
posixToRfc3339 dateTime =
    Rfc3339.DateTimeOffset
        { instant = dateTime
        , offset = { hour = 0, minute = 0 }
        }
        |> Rfc3339.toString


ensureEndsInSlash : String -> String
ensureEndsInSlash url =
    if String.endsWith "/" url then
        url

    else
        url ++ "/"
