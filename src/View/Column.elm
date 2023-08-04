module View.Column exposing
    ( Spacing(..)
    , setSpaced
    )

import Element as Ui
import Style


type Spacing
    = NoSpacing
    | SSpacing
    | MSpacing


setSpaced : Spacing -> List (Ui.Element msg) -> Ui.Element msg
setSpaced spacing blocks =
    let
        spacingSize =
            case spacing of
                NoSpacing ->
                    0

                SSpacing ->
                    Style.spacing.size1

                MSpacing ->
                    Style.spacing.size4
    in
    Ui.column
        [ Ui.spacing spacingSize
        , Ui.width Ui.fill
        ]
        blocks
