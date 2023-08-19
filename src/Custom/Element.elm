module Custom.Element exposing
    ( hiddenToScreenReaders
    , id
    , nonSelectable
    , varFontSize
    , varLineSpacing
    , varLineSpacingFromFontSize
    , varPaddingBottom
    , varPaddingTop
    , varWidth
    )

import Element as Ui
import Html.Attributes


{-| Sets `aria-hidden` on the element.
-}
hiddenToScreenReaders : Ui.Attribute msg
hiddenToScreenReaders =
    Html.Attributes.attribute "aria-hidden" "true"
        |> Ui.htmlAttribute


nonSelectable : Ui.Attribute msg
nonSelectable =
    Html.Attributes.style "user-select" "none"
        |> Ui.htmlAttribute


id : String -> Ui.Attribute msg
id id_ =
    Html.Attributes.id id_
        |> Ui.htmlAttribute


varWidth : String -> Ui.Attribute msg
varWidth =
    basicVarAttribute "width"


varFontSize : String -> Ui.Attribute msg
varFontSize =
    basicVarAttribute "font-size"


varLineSpacing : String -> Ui.Attribute msg
varLineSpacing varName =
    "calc(1em + var(--{varName}))"
        |> String.replace "{varName}" varName
        |> Html.Attributes.style "line-height"
        |> Ui.htmlAttribute


varLineSpacingFromFontSize : String -> Float -> Ui.Attribute msg
varLineSpacingFromFontSize fontSizeVarName lineSpacingFactor =
    "calc(1em + (var(--{fontSizeVarName}) * {lineSpacingFactor}))"
        |> String.replace "{fontSizeVarName}" fontSizeVarName
        |> String.replace "{lineSpacingFactor}" (String.fromFloat lineSpacingFactor)
        |> Html.Attributes.style "line-height"
        |> Ui.htmlAttribute


varPaddingTop : String -> Ui.Attribute msg
varPaddingTop =
    basicVarAttribute "padding-top"


varPaddingBottom : String -> Ui.Attribute msg
varPaddingBottom =
    basicVarAttribute "padding-bottom"



-- INTERNAL


basicVarAttribute : String -> String -> Ui.Attribute msg
basicVarAttribute attributeName varName =
    "var(--{varName})"
        |> String.replace "{varName}" varName
        |> Html.Attributes.style attributeName
        |> Ui.htmlAttribute
