module View.Inline exposing
    ( setBold
    , setItalic
    , setLink
    , setStrikethrough
    )

import Custom.Color as Color
import Element as Ui
import Element.Font as UiFont
import Style


setBold : List (Ui.Element msg) -> Ui.Element msg
setBold children =
    setStyle UiFont.bold children


setItalic : List (Ui.Element msg) -> Ui.Element msg
setItalic children =
    setStyle UiFont.italic children


setStrikethrough : List (Ui.Element msg) -> Ui.Element msg
setStrikethrough children =
    setStyle UiFont.strike children


setLink : String -> List (Ui.Element msg) -> Ui.Element msg
setLink destination children =
    Ui.link []
        { url = destination
        , label =
            Ui.paragraph
                [ UiFont.underline
                , UiFont.color (Style.color.secondary70 |> Color.toElmUi)
                ]
                children
        }



-- INTERNAL


setStyle : Ui.Attribute msg -> List (Ui.Element msg) -> Ui.Element msg
setStyle attr children =
    Ui.paragraph [ attr ] children
