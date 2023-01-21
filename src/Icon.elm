module Icon exposing (..)

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



-- INTERNAL


style : Size -> (List (Attribute msg) -> Html msg) -> Ui.Element msg
style size icon =
    icon
        [ HtmlAttr.style "width" "1em"
        ]
        |> Ui.html
