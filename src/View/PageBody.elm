module View.PageBody exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (class)
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
        pageMaxWidth =
            "max-w-[40rem]"

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
                    Html.div
                        [ class "flex w-full flex-col items-center"
                        , Sand.backgroundColor Style.color.layout05
                        ]
                        [ Html.div [ class ("w-full flex-grow p-4 " ++ pageMaxWidth) ]
                            [ title_ ]
                        ]

        content : Html msg
        content =
            Html.div [ class "flex w-full flex-col items-center" ]
                [ Html.div [ class ("w-full px-4 pb-32 pt-6 " ++ pageMaxWidth) ]
                    [ config.content ]
                ]
    in
    [ header
    , content
    ]
        |> View.Column.setSpaced NoSpacing
        |> Html.map PagesMsg.fromMsg
