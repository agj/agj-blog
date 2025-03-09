module View.Heading exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (class)


view : Int -> List (Html msg) -> Html msg
view level content =
    let
        normalizedLevel : Int
        normalizedLevel =
            max 1 level

        { el, classes, prepend } =
            case normalizedLevel of
                1 ->
                    { el = Html.h1
                    , classes = "text-4xl font-bold"
                    , prepend = Nothing
                    }

                2 ->
                    { el = Html.h2
                    , classes = "text-2xl font-bold"
                    , prepend = Nothing
                    }

                3 ->
                    { el = Html.h3
                    , classes = "text-xl font-bold"
                    , prepend = Nothing
                    }

                4 ->
                    { el = Html.h4
                    , classes = "text-lg font-bold"
                    , prepend = Nothing
                    }

                _ ->
                    { el =
                        if normalizedLevel == 5 then
                            Html.h5

                        else
                            Html.h6
                    , classes = "text-lg"
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
    el [ class ("leading-snug w-full pt-4 " ++ classes) ]
        (prependEl :: content)
