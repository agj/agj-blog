module View.List exposing
    ( ViewList
    , fromItems
    , view
    , withNumbers
    )

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Font as UiFont
import Html exposing (Html)
import Html.Attributes
import Markdown.Block exposing (Block(..))
import Order.Extra exposing (isOrdered)
import Sand
import Style
import View.Column exposing (Spacing(..))
import View.Paragraph


type ViewList msg
    = ViewList
        { startNumber : Maybe Int
        , items : List (List (Ui.Element msg))
        }


fromItems : List (List (Ui.Element msg)) -> ViewList msg
fromItems items =
    ViewList
        { startNumber = Nothing
        , items = items
        }


withNumbers : Int -> ViewList msg -> ViewList msg
withNumbers startNumber (ViewList config) =
    ViewList { config | startNumber = Just startNumber }


view : ViewList msg -> Ui.Element msg
view (ViewList { items, startNumber }) =
    let
        renderItem : List (Ui.Element msg) -> Html msg
        renderItem item =
            Html.li []
                [ item
                    |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])
                    |> View.Column.setSpaced SSpacing
                ]

        renderedItems : List (Html msg)
        renderedItems =
            items
                |> List.map renderItem
    in
    Ui.html <|
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
