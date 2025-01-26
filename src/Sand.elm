module Sand exposing (GridCols(..), GridLength(..), Length(..), fr, gridCols)

import Html exposing (Html)
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


type GridLength
    = GlLength Length
    | GlFraction Int


type GridCols
    = GridCols (List GridLength)
    | ResponsiveGridCols (List ( Int, List GridLength ))


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


gridLengthToString : GridLength -> String
gridLengthToString gridLength =
    case gridLength of
        GlLength length ->
            lengthToString length

        GlFraction fraction ->
            String.fromInt fraction ++ "fr"
