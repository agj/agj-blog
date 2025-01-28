module View.Paragraph exposing (view)

import Html exposing (Html)
import Html.Attributes
import Sand


view : List (Html msg) -> Html msg
view inlines =
    Html.p
        [ Sand.fontSize Sand.TextM
        , Html.Attributes.style "line-height" "1.6"
        , Sand.paddingTop (Sand.LRaw "0.5em")
        , Sand.paddingBottom (Sand.LRaw "0.5em")
        , Sand.width (Sand.LRaw "100%")
        ]
        inlines
