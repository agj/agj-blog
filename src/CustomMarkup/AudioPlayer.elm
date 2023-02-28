module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , renderer
    , toElmUi
    , toHtml
    )

import CustomMarkup.AudioPlayer.Track exposing (Track)
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


toElmUi : AudioPlayer -> List Track -> Ui.Element msg
toElmUi audioPlayer tracks =
    let
        trackEls =
            tracks
                |> List.map trackToHtml
    in
    Html.article [ Attr.class "audio-player" ]
        (Html.header [] [ Html.text audioPlayer.title ]
            :: trackEls
        )
        |> Ui.html


toHtml : AudioPlayer -> List (Html msg) -> Html msg
toHtml audioPlayer children =
    Html.article [ Attr.class "audio-player" ]
        (Html.header [] [ Html.text audioPlayer.title ]
            :: children
        )



-- INTERNAL


trackToHtml : Track -> Html msg
trackToHtml track =
    Html.figure [ Attr.class "track" ]
        [ Html.figcaption [] [ Html.text track.title ]
        , Html.audio
            [ Attr.controls True
            , Attr.src track.src
            , Attr.preload "none"
            ]
            []
        ]
