module Sand exposing
    ( GridCols(..)
    , GridLength(..)
    , Length(..)
    , TextSize(..)
    , backgroundColor
    , borderColor
    , div
    , fontColor
    , fr
    , none
    , setAttributeIf
    )

import Color exposing (Color)
import Html exposing (Html)
import Html.Attributes
import TypedSvg.Types exposing (FontSizeAdjust(..))


type Length
    = L0
    | L1
    | L2
    | L3
    | L4
    | L5
    | L6
    | L7
    | L8
    | L9
    | L10
    | LRaw String


type TextSize
    = TextM
    | TextL
    | TextXl
    | TextXxl


type GridLength
    = GlLength Length
    | GlFraction Int


type GridCols
    = GridCols (List GridLength)
    | ResponsiveGridCols (List ( Int, List GridLength ))


div : List (Html.Attribute msg) -> List (Html msg) -> Html msg
div attrs =
    Html.div
        ([ Html.Attributes.style "display" "flex"
         , Html.Attributes.style "flex-direction" "column"
         ]
            ++ attrs
        )


fr : Int -> GridLength
fr value =
    GlFraction value


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



-- INTERNAL
