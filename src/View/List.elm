module View.List exposing
    ( ViewList
    , fromItems
    , view
    , withNumbers
    )

import Html exposing (Html)
import Html.Attributes
import Sand
import View.Column exposing (Spacing(..))


type ViewList msg
    = ViewList
        { startNumber : Maybe Int
        , items : List (List (Html msg))
        }


fromItems : List (List (Html msg)) -> ViewList msg
fromItems items =
    ViewList
        { startNumber = Nothing
        , items = items
        }


withNumbers : Int -> ViewList msg -> ViewList msg
withNumbers startNumber (ViewList config) =
    ViewList { config | startNumber = Just startNumber }


view : ViewList msg -> Html msg
view (ViewList { items, startNumber }) =
    let
        renderItem : List (Html msg) -> Html msg
        renderItem item =
            Html.li []
                [ item
                    |> View.Column.setSpaced SSpacing
                ]

        renderedItems : List (Html msg)
        renderedItems =
            items
                |> List.map renderItem
    in
    case startNumber of
        Just num ->
            Sand.ol
                [ Sand.gap Sand.L3
                , Html.Attributes.attribute "start" (String.fromInt num)
                ]
                renderedItems

        Nothing ->
            Sand.ul
                [ Sand.gap Sand.L3 ]
                renderedItems
