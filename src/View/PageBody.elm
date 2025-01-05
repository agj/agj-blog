module View.PageBody exposing (..)

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import PagesMsg exposing (PagesMsg)
import Style
import View.Column exposing (Spacing(..))
import View.Heading


type PageBody msg
    = PageBody
        { content : Ui.Element msg
        , title : PageTitle msg
        }


type PageTitle msg
    = NoPageTitle
    | PageTitleOnly (List (Ui.Element msg))
    | PageTitleAndSubtitle (List (Ui.Element msg)) (Ui.Element msg)


fromContent : Ui.Element msg -> PageBody msg
fromContent content =
    PageBody
        { content = content
        , title = NoPageTitle
        }


withTitle : List (Ui.Element msg) -> PageBody msg -> PageBody msg
withTitle titleInlines (PageBody config) =
    PageBody { config | title = PageTitleOnly titleInlines }


withTitleAndSubtitle : List (Ui.Element msg) -> Ui.Element msg -> PageBody msg -> PageBody msg
withTitleAndSubtitle titleInlines subtitleBlock (PageBody config) =
    PageBody { config | title = PageTitleAndSubtitle titleInlines subtitleBlock }


view : PageBody msg -> Ui.Element (PagesMsg msg)
view (PageBody config) =
    let
        title =
            case config.title of
                NoPageTitle ->
                    Nothing

                PageTitleOnly title_ ->
                    View.Heading.view 1 title_
                        |> Just

                PageTitleAndSubtitle title_ subtitle ->
                    [ View.Heading.view 1 title_
                    , subtitle
                    ]
                        |> View.Column.setSpaced MSpacing
                        |> Just

        header =
            case title of
                Nothing ->
                    Ui.none

                Just title_ ->
                    Ui.el
                        [ Ui.width (Ui.px 900)
                        , Ui.centerX
                        , Ui.varPadding Style.spacing.size4
                        ]
                        title_
                        |> Ui.el
                            [ Ui.width Ui.fill
                            , UiBackground.color (Style.color.layout05 |> Color.toElmUi)
                            ]

        content =
            Ui.el
                [ Ui.width (Ui.px 900)
                , Ui.centerX
                , Ui.varPaddingTop Style.spacing.size6
                , Ui.varPaddingLeft Style.spacing.size4
                , Ui.varPaddingRight Style.spacing.size4
                , Ui.varPaddingBottom Style.spacing.size9
                ]
                config.content
                |> Ui.el
                    [ Ui.width Ui.fill
                    ]
    in
    [ header
    , content
    ]
        |> View.Column.setSpaced NoSpacing
        |> Ui.map PagesMsg.fromMsg
