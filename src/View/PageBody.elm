module View.PageBody exposing (..)

import Html exposing (Html)
import PagesMsg exposing (PagesMsg)
import Sand
import Style
import View.Column exposing (Spacing(..))
import View.Heading


type PageBody msg
    = PageBody
        { content : Html msg
        , title : PageTitle msg
        }


type PageTitle msg
    = NoPageTitle
    | PageTitleOnly (List (Html msg))
    | PageTitleAndSubtitle (List (Html msg)) (Html msg)


fromContent : Html msg -> PageBody msg
fromContent content =
    PageBody
        { content = content
        , title = NoPageTitle
        }


withTitle : List (Html msg) -> PageBody msg -> PageBody msg
withTitle titleInlines (PageBody config) =
    PageBody { config | title = PageTitleOnly titleInlines }


withTitleAndSubtitle : List (Html msg) -> Html msg -> PageBody msg -> PageBody msg
withTitleAndSubtitle titleInlines subtitleBlock (PageBody config) =
    PageBody { config | title = PageTitleAndSubtitle titleInlines subtitleBlock }


view : PageBody msg -> Html (PagesMsg msg)
view (PageBody config) =
    let
        title : Maybe (Html msg)
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

        header : Html msg
        header =
            case title of
                Nothing ->
                    Sand.none

                Just title_ ->
                    Sand.div
                        [ Sand.width (Sand.LRaw "100%")
                        , Sand.backgroundColor Style.color.layout05
                        ]
                        [ Sand.div
                            [ Sand.maxWidth (Sand.LRaw "900px")
                            , Sand.justifyContentCenter
                            , Sand.alightItemsCenter
                            , Sand.padding Sand.L4
                            ]
                            [ title_ ]
                        ]

        content : Html msg
        content =
            Sand.div [ Sand.width (Sand.LRaw "100%") ]
                [ Sand.div
                    [ Sand.maxWidth (Sand.LRaw "900px")
                    , Sand.justifyContentCenter
                    , Sand.alightItemsCenter
                    , Sand.paddingTop Sand.L6
                    , Sand.paddingLeft Sand.L4
                    , Sand.paddingRight Sand.L4
                    , Sand.paddingBottom Sand.L9
                    ]
                    [ config.content ]
                ]
    in
    [ header
    , content
    ]
        |> View.Column.setSpaced NoSpacing
        |> Html.map PagesMsg.fromMsg
