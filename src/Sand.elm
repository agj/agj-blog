module Sand exposing
    ( GridCols(..)
    , GridLength(..)
    , Length(..)
    , TextSize(..)
    , alightItemsCenter
    , backgroundColor
    , div
    , fr
    , gap
    , gridCols
    , justifyContentCenter
    , maxWidth
    , none
    , padding
    , paddingBottom
    , paddingLeft
    , paddingRight
    , paddingTop
    , textSizeToString
    , width
    )

import Color exposing (Color)
import Html exposing (Attribute, Html)
import Html.Attributes


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


gridCols : { cols : GridCols, gap : Length } -> List (Html msg) -> Html msg
gridCols config els =
    let
        className : String
        className =
            "grid-cols-temp"

        mediaQuery { maxWidth, gridLengths } =
            (if maxWidth > 0 then
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
                |> String.replace "{maxWidth}" (String.fromInt maxWidth ++ "px")
                |> String.replace "{className}" className
                |> String.replace "{cols}" (gridLengthsToString gridLengths)

        styles : String
        styles =
            case config.cols of
                GridCols gridLengths ->
                    mediaQuery { maxWidth = 0, gridLengths = gridLengths }

                ResponsiveGridCols defs ->
                    defs
                        |> List.map
                            (\( maxWidth, gridLengths ) ->
                                mediaQuery { maxWidth = maxWidth, gridLengths = gridLengths }
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


gap : Length -> Html.Attribute msg
gap length =
    Html.Attributes.style "gap" (lengthToString length)



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
