module View.Inline exposing
    ( setBold
    , setItalic
    , setStrikethrough
    )

import Element as Ui
import Element.Font as UiFont


setBold : List (Ui.Element msg) -> Ui.Element msg
setBold children =
    setStyle UiFont.bold children


setItalic : List (Ui.Element msg) -> Ui.Element msg
setItalic children =
    setStyle UiFont.italic children


setStrikethrough : List (Ui.Element msg) -> Ui.Element msg
setStrikethrough children =
    setStyle UiFont.strike children



-- INTERNAL


setStyle : Ui.Attribute msg -> List (Ui.Element msg) -> Ui.Element msg
setStyle attr children =
    Ui.paragraph [ attr ] children
