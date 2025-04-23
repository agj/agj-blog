module Data.AtomFeed exposing (..)

import Custom.Markdown
import Data.Post as Post exposing (Post)
import DateOrDateTime exposing (toIso8601)
import Html.Attributes exposing (datetime)
import Iso8601
import Time


generate :
    { title : String
    , url : String
    , description : String
    }
    -> List Post
    -> String
generate config posts =
    """<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title><![CDATA[{title}]]></title>
  <link href="{url}"/>
  <updated>{updated}</updated>
  <author>
    <name>agj</name>
  </author>
  <id>TODO</id>

{entries}
</feed>
    """
        |> String.replace "{title}" ""
        |> String.replace "{url}" ""
        |> String.replace "{updated}"
            (posts
                |> List.sortBy (\post -> Time.posixToMillis post.gist.dateTime)
                |> List.reverse
                |> List.head
                |> Maybe.map (\post -> post.gist.dateTime)
                |> Maybe.withDefault (Time.millisToPosix 0)
                |> Iso8601.fromTime
            )
        |> String.replace "{entries}"
            (posts
                |> List.map
                    (\post ->
                        generateEntry
                            { title = post.gist.title
                            , url = Post.gistToUrl post.gist
                            , summary = Custom.Markdown.getSummary post.markdown
                            , updated = post.gist.dateTime
                            }
                    )
                |> String.join ""
            )



-- INTERNAL


generateEntry :
    { title : String
    , url : String
    , summary : String
    , updated : Time.Posix
    }
    -> String
generateEntry c =
    """
  <entry>
    <title><![CDATA[{title}]]></title>
    <link href="{url}"/>
    <id>{url}</id>
    <updated>{updated}</updated>
    <summary><![CDATA[{summary}]]></summary>
  </entry>
    """
        |> String.replace "{title}" c.title
        |> String.replace "{url}" c.url
        |> String.replace "{updated}" (Iso8601.fromTime c.updated)
        |> String.replace "{summary}" c.summary
