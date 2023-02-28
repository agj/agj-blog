module CustomMarkup.AudioPlayer.Track exposing
    ( Track
    , renderer
    )

import Markdown.Html


type alias Track =
    { title : String
    , src : String
    }


renderer : Markdown.Html.Renderer Track
renderer =
    Markdown.Html.tag "track" Track
        |> Markdown.Html.withAttribute "title"
        |> Markdown.Html.withAttribute "src"
