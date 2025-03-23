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
                    Html.h1 [ class "text-4xl leading-snug w-full font-light" ]
                        title_
                        |> Just

                PageTitleAndSubtitle title_ subtitle ->
                    Html.div [ class "flex flex-col" ]
                        [ Html.h1 [ class "text-4xl leading-snug w-full font-light" ]
                            title_
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
                    Html.div [ class "p-2 pb-0" ]
                        [ Html.header [ class "bg-layout-05 flex w-full flex-col items-center rounded-lg" ]
                            [ Html.div [ class ("flex w-full flex-row justify-end mt-2 " ++ pageMaxWidth) ]
                                [ changeThemeButtonView config ]
                            , Html.div [ class ("w-full flex-grow px-4 pb-2 " ++ pageMaxWidth) ]
                                [ title_ ]
                            ]
                        ]

        content : Html msg
        content =
            Html.div [ class "flex w-full flex-col items-center" ]
                [ Html.main_ [ class ("w-full px-4 pb-32 pt-6 " ++ pageMaxWidth) ]
                    [ config.content ]
                ]
    in
    Html.div [ class "text-layout-90 flex w-full flex-col" ]
        [ header
        , content
        ]
        |> Html.map PagesMsg.fromMsg


changeThemeButtonView :
    { a
        | theme : Theme
        , onRequestedChangeTheme : msg
    }
    -> Html msg
changeThemeButtonView config =
    let
        nextTheme =
            Theme.change config.theme
    in
    Html.button
        [ class "text-layout-50 hover:bg-layout-20 flex size-6 justify-center rounded bg-white align-middle hover:text-white"
        , class "button"
        , Html.Events.onClick config.onRequestedChangeTheme
        ]
        [ (case ( nextTheme.set, nextTheme.default ) of
            ( Just Theme.Dark, _ ) ->
                Icon.moon

            ( Just Theme.Light, _ ) ->
                Icon.sun

            ( Nothing, _ ) ->
                Icon.minus
          )
            Icon.Small
        ]
