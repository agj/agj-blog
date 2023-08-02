module View.List exposing
    ( ViewList
    , fromItems
    , view
    , withNumbers
    )

import Element as Ui
import Style
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
        |> wrapBlocks



-- INTERNAL


viewListItem : String -> List (Ui.Element msg) -> Ui.Element msg
viewListItem bulletText item =
    let
        bullet =
            [ Ui.text bulletText ]
                |> View.Paragraph.view
                |> Ui.el
                    [ Ui.alignTop
                    , Ui.width (Ui.px Style.spacing.size6)
                    ]

        addBullet content =
            Ui.row [ Ui.width Ui.fill ]
                [ bullet
                , content
                ]
    in
    item
        |> wrapBlocks
        |> addBullet


wrapBlocks : List (Ui.Element msg) -> Ui.Element msg
wrapBlocks els =
    Ui.column
        [ Ui.spacing Style.spacing.size1
        , Ui.width Ui.fill
        ]
        els
