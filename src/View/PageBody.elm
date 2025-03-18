module View.PageBody exposing (..)

import Color
import Custom.Html
import Custom.Html.Attributes exposing (customProperties)
import Html exposing (Html)
import Html.Attributes exposing (class)
import PagesMsg exposing (PagesMsg)
import Style
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
    Html.div
        [ class "flex w-full flex-col"
        , customProperties
            [ ( "color-layout-90", Style.color.layout90 |> Color.toCssString )
            , ( "color-layout-80", Style.color.layout80 |> Color.toCssString )
            , ( "color-layout-70", Style.color.layout70 |> Color.toCssString )
            , ( "color-layout-60", Style.color.layout60 |> Color.toCssString )
            , ( "color-layout-50", Style.color.layout50 |> Color.toCssString )
            , ( "color-layout-40", Style.color.layout40 |> Color.toCssString )
            , ( "color-layout-30", Style.color.layout30 |> Color.toCssString )
            , ( "color-layout-20", Style.color.layout20 |> Color.toCssString )
            , ( "color-layout-10", Style.color.layout10 |> Color.toCssString )
            , ( "color-layout-05", Style.color.layout05 |> Color.toCssString )
            , ( "color-primary-90", Style.color.primary90 |> Color.toCssString )
            , ( "color-primary-80", Style.color.primary80 |> Color.toCssString )
            , ( "color-primary-70", Style.color.primary70 |> Color.toCssString )
            , ( "color-primary-60", Style.color.primary60 |> Color.toCssString )
            , ( "color-primary-50", Style.color.primary50 |> Color.toCssString )
            , ( "color-primary-40", Style.color.primary40 |> Color.toCssString )
            , ( "color-primary-30", Style.color.primary30 |> Color.toCssString )
            , ( "color-primary-20", Style.color.primary20 |> Color.toCssString )
            , ( "color-primary-10", Style.color.primary10 |> Color.toCssString )
            , ( "color-primary-05", Style.color.primary05 |> Color.toCssString )
            , ( "color-transparent", "transparent" )
            , ( "color-white", "white" )
            ]
        ]
        [ header
        , content
        ]
        |> Html.map PagesMsg.fromMsg
