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
        , Ui.varFontSize Style.textSize.m
        , Ui.varLineSpacing (Style.interline.m Style.textSize.m)
        , Ui.varPaddingTop (Style.blockPadding Style.textSize.m Style.interline.m)
        , Ui.varPaddingBottom (Style.blockPadding Style.textSize.m Style.interline.m)
        , Ui.width Ui.fill
        ]
        inlines
