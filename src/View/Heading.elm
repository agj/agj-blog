module View.Heading exposing (..)

import Html exposing (Html)
import Html.Attributes
import Sand


view : Int -> List (Html msg) -> Html msg
view level content =
    let
        normalizedLevel : Int
        normalizedLevel =
            max 1 level

        baseStyles : List (Html.Attribute msg)
        baseStyles =
            [ Sand.fontSize fontSize
            , Html.Attributes.style "line-height" "1.4"
            , Sand.width (Sand.LRaw "100%")
            , Sand.paddingTop Sand.L4
            ]

        { el, fontSize, styles, prepend } =
            case normalizedLevel of
                1 ->
                    { el = Html.h1
                    , fontSize = Sand.TextXxl
                    , styles = [ Html.Attributes.style "font-weight" "bold" ]
                    , prepend = Nothing
                    }

                2 ->
                    { el = Html.h2
                    , fontSize = Sand.TextXl
                    , styles = [ Html.Attributes.style "font-weight" "bold" ]
                    , prepend = Nothing
                    }

                3 ->
                    { el = Html.h3
                    , fontSize = Sand.TextL
                    , styles = [ Html.Attributes.style "font-weight" "bold" ]
                    , prepend = Nothing
                    }

                4 ->
                    { el = Html.h4
                    , fontSize = Sand.TextL
                    , styles = []
                    , prepend = Nothing
                    }

                _ ->
                    { el =
                        if normalizedLevel == 5 then
                            Html.h5

                        else
                            Html.h6
                    , fontSize = Sand.TextL
                    , styles = []
                    , prepend = Just (String.repeat (normalizedLevel - 4) "▹")
                    }

        prependEl : Html msg
        prependEl =
            case prepend of
                Just text ->
                    Html.span
                        [ Html.Attributes.attribute "aria-hidden" "true"
                        , Html.Attributes.style "user-select" "none"
                        ]
                        [ Html.text (text ++ " ") ]

                Nothing ->
                    Html.text ""
    in
    el (baseStyles ++ styles)
        (prependEl :: content)
