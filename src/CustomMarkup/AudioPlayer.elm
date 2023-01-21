module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , renderer
    , toElmUi
    , toHtml
    )

import Element as Ui
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


toElmUi : AudioPlayer -> List (Ui.Element msg) -> Ui.Element msg
toElmUi audioPlayer children =
    toHtml audioPlayer
        (children |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []))
        |> Ui.html


toHtml : AudioPlayer -> List (Html msg) -> Html msg
toHtml audioPlayer children =
    Html.article [ Attr.class "audio-player" ]
        (Html.header [] [ Html.text audioPlayer.title ]
            :: children
        )
