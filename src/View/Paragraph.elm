module View.Paragraph exposing (view)

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Font as UiFont
import Style


view : List (Ui.Element msg) -> Ui.Element msg
view inlines =
    Ui.paragraph
        [ UiFont.color (Color.toElmUi Style.color.layout)
        , Ui.varFontSize Style.textSizeVar.m
        , Ui.varLineSpacing (Style.interlineVar.m Style.textSizeVar.m)
        , Ui.varPaddingTop (Style.blockPaddingVar Style.textSizeVar.m Style.interlineVar.m)
        , Ui.varPaddingBottom (Style.blockPaddingVar Style.textSizeVar.m Style.interlineVar.m)
        , Ui.width Ui.fill
        ]
        inlines
