module Sand exposing
    ( GridCols(..)
    , GridLength(..)
    , Length(..)
    , TextSize(..)
    , alightItemsCenter
    , backgroundColor
    , borderRadius
    , div
    , fontColor
    , fontSize
    , fr
    , gap
    , gridCols
    , height
    , justifyContentCenter
    , margin
    , marginBottom
    , marginLeft
    , marginRight
    , marginTop
    , maxWidth
    , none
    , ol
    , padding
    , paddingBottom
    , paddingLeft
    , paddingRight
    , paddingTop
    , setAttributeIf
    , textAlignCenter
    , ul
    , width
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


ol : List (Html.Attribute msg) -> List (Html msg) -> Html msg
ol attrs =
    Html.ol
        ([ Html.Attributes.style "display" "flex"
         , Html.Attributes.style "flex-direction" "column"
         ]
            ++ attrs
        )


ul : List (Html.Attribute msg) -> List (Html msg) -> Html msg
ul attrs =
    Html.ul
        ([ Html.Attributes.style "display" "flex"
         , Html.Attributes.style "flex-direction" "column"
         ]
            ++ attrs
        )


gridCols : { cols : GridCols, gap : Length } -> List (Html msg) -> Html msg
gridCols config els =
    let
        className : String
        className =
            "grid-cols-temp"

        mediaQuery { maxWidth_, gridLengths } =
            (if maxWidth_ > 0 then
                """
                @media (max-width: {maxWidth}) {
                    .{className} {
                        grid-template-columns: {cols};
                    }
                }
                """

             else
                """
                .{className} {
                    grid-template-columns: {cols};
                }
                """
            )
                |> String.replace "{maxWidth}" (String.fromInt maxWidth_ ++ "px")
                |> String.replace "{className}" className
                |> String.replace "{cols}" (gridLengthsToString gridLengths)

        styles : String
        styles =
            case config.cols of
                GridCols gridLengths ->
                    mediaQuery { maxWidth_ = 0, gridLengths = gridLengths }

                ResponsiveGridCols defs ->
                    defs
                        |> List.map
                            (\( maxWidth_, gridLengths ) ->
                                mediaQuery { maxWidth_ = maxWidth_, gridLengths = gridLengths }
                            )
                        |> String.join ""

        styleEl =
            Html.node "style" [] [ Html.text styles ]
    in
    Html.div
        [ Html.Attributes.style "display" "grid"
        , Html.Attributes.style "gap" (lengthToString config.gap)
        , Html.Attributes.class className
        ]
        (styleEl :: els)


fr : Int -> GridLength
fr value =
    GlFraction value


none : Html msg
none =
    Html.text ""


width : Length -> Html.Attribute msg
width length =
    Html.Attributes.style "width" (lengthToString length)


height : Length -> Html.Attribute msg
height length =
    Html.Attributes.style "height" (lengthToString length)


maxWidth : Length -> Html.Attribute msg
maxWidth length =
    Html.Attributes.style "max-width" (lengthToString length)


backgroundColor : Color -> Html.Attribute msg
backgroundColor color_ =
    Html.Attributes.style "background-color" (Color.toCssString color_)


justifyContentCenter : Html.Attribute msg
justifyContentCenter =
    Html.Attributes.style "justify-content" "center"


alightItemsCenter : Html.Attribute msg
alightItemsCenter =
    Html.Attributes.style "align-items" "center"


textAlignCenter : Html.Attribute msg
textAlignCenter =
    Html.Attributes.style "text-align" "center"


padding : Length -> Html.Attribute msg
padding length =
    Html.Attributes.style "padding" (lengthToString length)


paddingTop : Length -> Html.Attribute msg
paddingTop length =
    Html.Attributes.style "padding-top" (lengthToString length)


paddingRight : Length -> Html.Attribute msg
paddingRight length =
    Html.Attributes.style "padding-right" (lengthToString length)


paddingBottom : Length -> Html.Attribute msg
paddingBottom length =
    Html.Attributes.style "padding-bottom" (lengthToString length)


paddingLeft : Length -> Html.Attribute msg
paddingLeft length =
    Html.Attributes.style "padding-left" (lengthToString length)


margin : Length -> Html.Attribute msg
margin length =
    Html.Attributes.style "margin" (lengthToString length)


marginTop : Length -> Html.Attribute msg
marginTop length =
    Html.Attributes.style "margin-top" (lengthToString length)


marginRight : Length -> Html.Attribute msg
marginRight length =
    Html.Attributes.style "margin-right" (lengthToString length)


marginBottom : Length -> Html.Attribute msg
marginBottom length =
    Html.Attributes.style "margin-bottom" (lengthToString length)


marginLeft : Length -> Html.Attribute msg
marginLeft length =
    Html.Attributes.style "margin-left" (lengthToString length)


gap : Length -> Html.Attribute msg
gap length =
    Html.Attributes.style "gap" (lengthToString length)


fontSize : TextSize -> Html.Attribute msg
fontSize textSize =
    Html.Attributes.style "font-size" (textSizeToString textSize)


fontColor : Color -> Html.Attribute msg
fontColor color =
    Html.Attributes.style "color" (Color.toCssString color)


borderRadius : Length -> Html.Attribute msg
borderRadius length =
    Html.Attributes.style "border-radius" (lengthToString length)


setAttributeIf : Bool -> Html.Attribute msg -> Html.Attribute msg
setAttributeIf cond attribute =
    if cond then
        attribute

    else
        Html.Attributes.classList []



-- INTERNAL


gridLengthsToString : List GridLength -> String
gridLengthsToString gridLengths =
    gridLengths
        |> List.map gridLengthToString
        |> String.join " "


lengthToString : Length -> String
lengthToString length =
    case length of
        L0 ->
            "0"

        L1 ->
            "1px"

        L2 ->
            "2px"

        L3 ->
            "4px"

        L4 ->
            "8px"

        L5 ->
            "16px"

        L6 ->
            "32px"

        L7 ->
            "64px"

        L8 ->
            "128px"

        L9 ->
            "256px"

        L10 ->
            "512px"

        LRaw rawLength ->
            rawLength


textSizeToString : TextSize -> String
textSizeToString textSize =
    case textSize of
        TextM ->
            "18px"

        TextL ->
            "24px"

        TextXl ->
            "35px"

        TextXxl ->
            "60px"


gridLengthToString : GridLength -> String
gridLengthToString gridLength =
    case gridLength of
        GlLength length ->
            lengthToString length

        GlFraction fraction ->
            String.fromInt fraction ++ "fr"
