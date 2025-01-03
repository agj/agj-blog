module Custom.Element exposing
    ( hiddenToScreenReaders
    , id
    , nonSelectable
    , varBorderRounded
    , varFontSize
    , varLineSpacing
    , varPadding
    , varPaddingBottom
    , varPaddingLeft
    , varPaddingRight
    , varPaddingTop
    , varSpacing
    , varWidth
    , varWidthFix
    )

import Css
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


{-| Sets width via a CSS size.
Under some circumstances, it needs `varWidthFix` to also be applied on the same element.
-}
varWidth : Css.Expression -> Ui.Attribute msg
varWidth =
    basicVarAttribute "width"


{-| Fixes `varWidth` when it doesn't work. Apply to the same element.
-}
varWidthFix : Ui.Attribute msg
varWidthFix =
    Html.Attributes.style "flex-basis" "auto"
        |> Ui.htmlAttribute


varFontSize : Css.Expression -> Ui.Attribute msg
varFontSize =
    basicVarAttribute "font-size"


varLineSpacing : Css.Expression -> Ui.Attribute msg
varLineSpacing expression =
    Css.CalcAddition (Css.Ems 1) expression
        |> basicVarAttribute "line-height"


varPadding : Css.Expression -> Ui.Attribute msg
varPadding =
    basicVarAttribute "padding"


varPaddingTop : Css.Expression -> Ui.Attribute msg
varPaddingTop =
    basicVarAttribute "padding-top"


varPaddingRight : Css.Expression -> Ui.Attribute msg
varPaddingRight =
    basicVarAttribute "padding-right"


varPaddingBottom : Css.Expression -> Ui.Attribute msg
varPaddingBottom =
    basicVarAttribute "padding-bottom"


varPaddingLeft : Css.Expression -> Ui.Attribute msg
varPaddingLeft =
    basicVarAttribute "padding-left"


varSpacing : Css.Expression -> Ui.Attribute msg
varSpacing =
    basicVarAttribute "gap"


varBorderRounded : Css.Expression -> Ui.Attribute msg
varBorderRounded =
    basicVarAttribute "border-radius"



-- INTERNAL


basicVarAttribute : String -> Css.Expression -> Ui.Attribute msg
basicVarAttribute attributeName expression =
    expression
        |> Css.expressionToString
        |> Html.Attributes.style attributeName
        |> Ui.htmlAttribute
