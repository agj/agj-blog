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
        , Ui.varLineSpacingFromFontSize Style.textSizeVar.m Style.interlineFactor.m
        , Ui.varPaddingTop Style.blockPaddingVar.textSizeMInterlineM
        , Ui.varPaddingBottom Style.blockPaddingVar.textSizeMInterlineM
        , Ui.width Ui.fill
        ]
        inlines
