module Icon exposing
    ( Icon
    , Size(..)
    , foldLeft
    , foldRight
    , info
    , minus
    , moon
    , none
    , pause
    , play
    , plus
    , rss
    , stop
    , sun
    , xMark
    )

import Heroicons.Micro
import Heroicons.Mini
import Html exposing (Attribute, Html)
import Html.Attributes


type alias Icon msg =
    Size -> Html msg


type Size
    = Medium
    | Small


play : Icon msg
play =
    icon icons.play


pause : Icon msg
pause =
    icon icons.pause


stop : Icon msg
stop =
    icon icons.stop


moon : Icon msg
moon =
    icon icons.moon


sun : Icon msg
sun =
    icon icons.sun


minus : Icon msg
minus =
    icon icons.minus


plus : Icon msg
plus =
    icon icons.plus


xMark : Icon msg
xMark =
    icon icons.xMark


info : Icon msg
info =
    icon icons.info


rss : Icon msg
rss =
    icon icons.rss


foldLeft : Icon msg
foldLeft =
    icon icons.foldLeft


foldRight : Icon msg
foldRight =
    icon icons.foldRight


none : Icon msg
none size =
    Html.div
        [ Html.Attributes.style "width" (sizeToRems size)
        , Html.Attributes.style "height" (sizeToRems size)
        ]
        []



-- INTERNAL


icon :
    { md : List (Attribute msg) -> Html msg
    , sm : List (Attribute msg) -> Html msg
    }
    -> Size
    -> Html msg
icon { md, sm } size =
    let
        svg =
            case size of
                Medium ->
                    md

                Small ->
                    sm
    in
    svg [ Html.Attributes.style "width" (sizeToRems size) ]


sizeToRems : Size -> String
sizeToRems size =
    case size of
        Medium ->
            "1rem"

        Small ->
            "0.75rem"


icons =
    { play = { md = Heroicons.Mini.play, sm = Heroicons.Micro.play }
    , pause = { md = Heroicons.Mini.pause, sm = Heroicons.Micro.pause }
    , stop = { md = Heroicons.Mini.stop, sm = Heroicons.Micro.stop }
    , moon = { md = Heroicons.Mini.moon, sm = Heroicons.Micro.moon }
    , sun = { md = Heroicons.Mini.sun, sm = Heroicons.Micro.sun }
    , minus = { md = Heroicons.Mini.minus, sm = Heroicons.Micro.minus }
    , plus = { md = Heroicons.Mini.plus, sm = Heroicons.Micro.plus }
    , xMark = { md = Heroicons.Mini.xMark, sm = Heroicons.Micro.xMark }
    , info = { md = Heroicons.Mini.informationCircle, sm = Heroicons.Micro.informationCircle }
    , rss = { md = Heroicons.Mini.rss, sm = Heroicons.Micro.rss }
    , foldLeft = { md = Heroicons.Mini.chevronDoubleLeft, sm = Heroicons.Micro.chevronDoubleLeft }
    , foldRight = { md = Heroicons.Mini.chevronDoubleRight, sm = Heroicons.Micro.chevronDoubleRight }
    }
