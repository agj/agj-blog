module View.Paragraph exposing (view)

import Custom.Color as Color
import Element as Ui
import Element.Font as UiFont
import Style


view : List (Ui.Element msg) -> Ui.Element msg
view children =
    Ui.paragraph
        [ UiFont.color (Color.toElmUi Style.color.layout)
        , UiFont.size Style.textSize.m
        , Ui.spacing (Style.interline.m Style.textSize.m)
        , Ui.paddingXY 0 (Style.blockPadding Style.textSize.m Style.interline.m)
        , Ui.width Ui.fill
        ]
        children
