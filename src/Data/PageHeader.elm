module Data.PageHeader exposing (..)

import Html exposing (Html)


view : List (Html msg) -> Maybe (Html msg) -> Html msg
view title subtitleM =
    case subtitleM of
        Just subtitle ->
            Html.header []
                [ Html.node "hgroup"
                    []
                    [ Html.h1 [] title
                    , subtitle
                    ]
                ]

        Nothing ->
            Html.header []
                [ Html.h1 [] title
                ]
