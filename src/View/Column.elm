module View.Column exposing
    ( Spacing(..)
    , setSpaced
    )

import Html exposing (Html)
import Sand


type Spacing
    = NoSpacing
    | SSpacing
    | MSpacing


setSpaced : Spacing -> List (Html msg) -> Html msg
setSpaced spacing blocks =
    let
        spacingSize =
            case spacing of
                NoSpacing ->
                    Sand.L0

                SSpacing ->
                    Sand.L1

                MSpacing ->
                    Sand.L4
    in
    Sand.div
        [ Sand.gap spacingSize
        , Sand.width (Sand.LRaw "100%")
        ]
        blocks
