module CustomMarkup.AudioPlayer.Track exposing (..)

import CustomMarkup.AudioPlayer exposing (AudioPlayer)
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


toHtml : Track -> dropped -> Html msg
toHtml track children =
    Html.figure [ Attr.class "track" ]
        [ Html.figcaption [] [ Html.text track.title ]
        , Html.audio
            [ Attr.controls True
            , Attr.src track.src
            , Attr.preload "none"
            ]
            []
        ]
