module View.Paragraph exposing (view)

import Custom.Element as Ui
import Element as Ui
import Html exposing (Html)
import Style


view : List (Html msg) -> Ui.Element msg
view inlines =
    Ui.paragraph
        [ Ui.varFontSize Style.textSize.m
        , Ui.varLineSpacing (Style.interline.m Style.textSize.m)
        , Ui.varPaddingTop (Style.blockPadding Style.textSize.m Style.interline.m)
        , Ui.varPaddingBottom (Style.blockPadding Style.textSize.m Style.interline.m)
        , Ui.width Ui.fill
        ]
        (inlines |> List.map Ui.html)
