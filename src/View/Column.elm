module View.Column exposing
    ( Spacing(..)
    , setSpaced
    )

import Css
import Custom.Element as Ui
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
                    Css.Unitless 0

                SSpacing ->
                    Style.spacingVar.size1

                MSpacing ->
                    Style.spacingVar.size4
    in
    Ui.column
        [ Ui.varSpacing spacingSize
        , Ui.width Ui.fill
        ]
        blocks
