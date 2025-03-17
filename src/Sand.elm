module Sand exposing
    ( backgroundColor
    , borderColor
    , fontColor
    , none
    , setAttributeIf
    )

import Color exposing (Color)
import Html exposing (Html)
import Html.Attributes


none : Html msg
none =
    Html.text ""


backgroundColor : Color -> Html.Attribute msg
backgroundColor color_ =
    Html.Attributes.style "background-color" (Color.toCssString color_)


borderColor : Color -> Html.Attribute msg
borderColor color_ =
    Html.Attributes.style "border-color" (Color.toCssString color_)


fontColor : Color -> Html.Attribute msg
fontColor color =
    Html.Attributes.style "color" (Color.toCssString color)


setAttributeIf : Bool -> Html.Attribute msg -> Html.Attribute msg
setAttributeIf cond attribute =
    if cond then
        attribute

    else
        Html.Attributes.classList []
