module CustomMarkup.AudioPlayer.Track exposing
    ( Track
    , renderer
    , toElmUi
    , toHtml
    )

import CustomMarkup.AudioPlayer exposing (AudioPlayer)
import Element as Ui
import Html exposing (Html)
import Html.Attributes as Attr
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


toElmUi : Track -> dropped -> Ui.Element msg
toElmUi track _ =
    toHtml track ()
        |> Ui.html


toHtml : Track -> dropped -> Html msg
toHtml track _ =
    Html.figure [ Attr.class "track" ]
        [ Html.figcaption [] [ Html.text track.title ]
        , Html.audio
            [ Attr.controls True
            , Attr.src track.src
            , Attr.preload "none"
            ]
            []
        ]
