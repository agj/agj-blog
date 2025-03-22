module View.PageBody exposing
    ( PageBody
    , fromContent
    , view
    , withTitle
    , withTitleAndSubtitle
    )

import Custom.Html
import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Events
import Icon
import PagesMsg exposing (PagesMsg)
import Theme exposing (Theme)
import View.Heading


type PageBody msg
    = PageBody
        { content : Html msg
        , title : PageTitle msg
        , theme : Theme
        , onRequestedChangeTheme : msg
        }


type PageTitle msg
    = NoPageTitle
    | PageTitleOnly (List (Html msg))
    | PageTitleAndSubtitle (List (Html msg)) (Html msg)


fromContent :
    { theme : Theme
    , onRequestedChangeTheme : msg
    }
    -> Html msg
    -> PageBody msg
fromContent config content =
    PageBody
        { content = content
        , title = NoPageTitle
        , theme = config.theme
        , onRequestedChangeTheme = config.onRequestedChangeTheme
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
                    Html.div [ class "flex flex-col gap-4" ]
                        [ View.Heading.view 1 title_
                        , Html.div [ class "text-layout-40 text-sm" ]
                            [ subtitle ]
                        ]
                        |> Just

        header : Html msg
        header =
            case title of
                Nothing ->
                    Custom.Html.none

                Just title_ ->
                    Html.div [ class "bg-layout-05 flex w-full flex-col items-center" ]
                        [ Html.div [ class ("flex w-full flex-row justify-end mt-2 " ++ pageMaxWidth) ]
                            [ Html.button
                                [ class "text-layout-50 hover:bg-layout-20 flex size-6 justify-center rounded bg-white align-middle hover:text-white"
                                , class "button"
                                , Html.Events.onClick config.onRequestedChangeTheme
                                ]
                                [ (case config.theme of
                                    Theme.Light ->
                                        Icon.moon

                                    Theme.Dark ->
                                        Icon.sun

                                    Theme.Default Theme.Light ->
                                        Icon.moon

                                    Theme.Default Theme.Dark ->
                                        Icon.sun

                                    _ ->
                                        Icon.moon
                                  )
                                    Icon.Small
                                ]
                            ]
                        , Html.div [ class ("w-full flex-grow p-4 pt-0 " ++ pageMaxWidth) ]
                            [ title_ ]
                        ]

        content : Html msg
        content =
            Html.div [ class "flex w-full flex-col items-center" ]
                [ Html.div [ class ("w-full px-4 pb-32 pt-6 " ++ pageMaxWidth) ]
                    [ config.content ]
                ]
    in
    Html.div [ class "text-layout-90 flex w-full flex-col" ]
        [ header
        , content
        ]
        |> Html.map PagesMsg.fromMsg
