module Icon exposing
    ( Icon
    , Size(..)
    , moon
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
    | Small


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


moon : Icon msg
moon size =
    Heroicons.Solid.moon
        |> style size


none : Icon msg
none size =
    Html.div
        [ Html.Attributes.style "width" (sizeToRems size)
        , Html.Attributes.style "height" (sizeToRems size)
        ]
        []



-- INTERNAL


style : Size -> (List (Attribute msg) -> Html msg) -> Html msg
style size icon =
    icon [ Html.Attributes.style "width" (sizeToRems size) ]


sizeToRems : Size -> String
sizeToRems size =
    case size of
        Medium ->
            "1rem"

        Small ->
            "0.75rem"
