module Icon exposing
    ( Icon
    , Size(..)
    , none
    , pause
    , play
    , stop
    )

import Heroicons.Solid
import Html exposing (Attribute, Html)
import Html.Attributes


type alias Icon msg =
    Size -> Html msg


type Size
    = Medium


play : Icon msg
play size =
    Heroicons.Solid.play
        |> style size


pause : Icon msg
pause size =
    Heroicons.Solid.pause
        |> style size


stop : Icon msg
stop size =
    Heroicons.Solid.stop
        |> style size


none : Icon msg
none size =
    Html.div
        [ Html.Attributes.style "width" (sizeToEms size)
        , Html.Attributes.style "height" (sizeToEms size)
        ]
        []



-- INTERNAL


style : Size -> (List (Attribute msg) -> Html msg) -> Html msg
style size icon =
    icon [ Html.Attributes.style "width" (sizeToEms size) ]


sizeToEms : Size -> String
sizeToEms size =
    case size of
        Medium ->
            "1em"
