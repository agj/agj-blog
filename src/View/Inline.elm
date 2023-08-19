module View.Inline exposing
    ( setBold
    , setCode
    , setItalic
    , setLink
    , setStrikethrough
    )

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Element.Font as UiFont
import Html
import Html.Attributes
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


setCode : String -> Ui.Element msg
setCode code =
    [ Html.text code ]
        |> Html.span
            [ Html.Attributes.style "white-space" "pre-wrap" ]
        |> Ui.html
        |> Ui.el
            [ UiFont.family [ UiFont.monospace ]
            , Ui.varFontSize Style.textSizeMonospaceVar.m
            , UiBackground.color (Style.color.layout05 |> Color.toElmUi)
            , Ui.paddingXY Style.spacing.size1 0
            , UiBorder.rounded Style.spacing.size1
            , Html.Attributes.style "box-decoration-break" "clone"
                |> Ui.htmlAttribute
            ]


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
