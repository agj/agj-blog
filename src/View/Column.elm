module View.Column exposing
    ( Spacing(..)
    , setSpaced
    )

import Html exposing (Html)
import Html.Attributes exposing (class)


type Spacing
    = MSpacing


setSpaced : Spacing -> List (Html msg) -> Html msg
setSpaced spacing blocks =
    let
        spacingSize =
            case spacing of
                MSpacing ->
                    "gap-4"
    in
    Html.div [ class ("w-full flex flex-col " ++ spacingSize) ]
        blocks
