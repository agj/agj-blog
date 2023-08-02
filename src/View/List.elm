module View.List exposing
    ( ViewList
    , fromItems
    , view
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


view : ViewList msg -> Ui.Element msg
view (ViewList { items }) =
    let
        renderItem : List (Ui.Element msg) -> Ui.Element msg
        renderItem item =
            viewListItem "▪︎" item
    in
    items
        |> List.map renderItem
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
