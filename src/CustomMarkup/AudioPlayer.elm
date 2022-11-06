module CustomMarkup.AudioPlayer exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Html


type alias AudioPlayer =
    { title : String
    }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toHtml : AudioPlayer -> List (Html msg) -> Html msg
toHtml audioPlayer children =
    Html.article [ Attr.class "audio-player" ]
        (Html.header [] [ Html.text audioPlayer.title ]
            :: children
        )
