module Icon exposing
    ( Icon
    , Size(..)
    , fastForward
    , none
    , pause
    , play
    , rewind
    , stop
    )

import Element as Ui
import Heroicons.Solid
import Html exposing (Attribute, Html)
import Html.Attributes as HtmlAttr


type alias Icon msg =
    Size -> Ui.Element msg


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


rewind : Icon msg
rewind size =
    Heroicons.Solid.backward
        |> style size


fastForward : Icon msg
fastForward size =
    Heroicons.Solid.forward
        |> style size


stop : Icon msg
stop size =
    Heroicons.Solid.stop
        |> style size


none : Icon msg
none size =
    Html.div
        [ HtmlAttr.style "width" (sizeToEms size)
        , HtmlAttr.style "height" (sizeToEms size)
        ]
        []
        |> Ui.html



-- INTERNAL


style : Size -> (List (Attribute msg) -> Html msg) -> Ui.Element msg
style size icon =
    icon
        [ HtmlAttr.style "width" (sizeToEms size)
        ]
        |> Ui.html


sizeToEms : Size -> String
sizeToEms size =
    case size of
        Medium ->
            "1em"
