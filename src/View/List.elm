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
import Style exposing (padding)
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
        renderItem : Int -> List (Ui.Element msg) -> Ui.Element msg
        renderItem index item =
            case startNumber of
                Just num ->
                    viewListItem (String.fromInt (index + num) ++ ".") item

                Nothing ->
                    viewListItem "▪︎" item
    in
    items
        |> List.indexedMap renderItem
        |> View.Column.setSpaced SSpacing



-- INTERNAL


viewListItem : String -> List (Ui.Element msg) -> Ui.Element msg
viewListItem bulletText item =
    let
        bullet =
            [ Ui.el [ UiFont.color (Style.color.layout30 |> Color.toElmUi) ]
                (Ui.text bulletText)
            ]
                |> View.Paragraph.view
                |> Ui.el
                    [ Ui.alignTop
                    , UiFont.alignRight
                    , Ui.varPaddingRight Style.spacing.size2
                    ]

        addBullet content =
            Ui.el
                [ Ui.width Ui.fill
                , Ui.onLeft bullet
                ]
                content
    in
    item
        |> View.Column.setSpaced SSpacing
        |> addBullet
        |> Ui.el [ Ui.varPaddingLeft Style.spacing.size4 ]
