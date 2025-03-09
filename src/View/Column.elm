module View.Column exposing
    ( Spacing(..)
    , setSpaced
    )

import Html exposing (Html)
import Html.Attributes exposing (class)
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
                    "gap-0"

                SSpacing ->
                    "gap-1"

                MSpacing ->
                    "gap-4"
    in
    Html.div [ class ("w-full flex flex-col " ++ spacingSize) ]
        blocks
