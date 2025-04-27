module View.PageBody exposing
    ( Feeds(..)
    , PageBody
    , fromContent
    , view
    , withRssFeed
    , withTitle
    , withTitleAndSubtitle
    , withoutAboutLink
    )

import Custom.Html
import Custom.Html.Attributes exposing (ariaDescribedBy, roleTooltip)
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, href, id)
import Html.Events
import Icon
import PagesMsg exposing (PagesMsg)
import Theme exposing (Theme)


type PageBody msg
    = PageBody
        { content : Html msg
        , title : PageTitle msg
        , theme : Theme
        , rssFeed : Feeds msg
        , showAboutLink : Bool
        , onRequestedChangeTheme : msg
        }


type PageTitle msg
    = NoPageTitle
    | PageTitleOnly (List (Html msg))
    | PageTitleAndSubtitle (List (Html msg)) (Html msg)


type Feeds msg
    = FeedUrls { rssFeedUrl : String, atomFeedUrl : String }
    | NoFeedsWithExplanation String
    | NoFeeds


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
        , rssFeed = NoFeeds
        , showAboutLink = True
        }


withTitle : List (Html msg) -> PageBody msg -> PageBody msg
withTitle titleInlines (PageBody config) =
    PageBody { config | title = PageTitleOnly titleInlines }


withTitleAndSubtitle : List (Html msg) -> Html msg -> PageBody msg -> PageBody msg
withTitleAndSubtitle titleInlines subtitleBlock (PageBody config) =
    PageBody { config | title = PageTitleAndSubtitle titleInlines subtitleBlock }


withRssFeed : Feeds msg -> PageBody msg -> PageBody msg
withRssFeed rssFeed (PageBody config) =
    PageBody { config | rssFeed = rssFeed }


withoutAboutLink : PageBody msg -> PageBody msg
withoutAboutLink (PageBody config) =
    PageBody { config | showAboutLink = False }


view : PageBody msg -> Html (PagesMsg msg)
view (PageBody config) =
    let
        pageMaxWidth =
            "max-w-[40rem]"

        titleEl : List (Html msg) -> Html msg
        titleEl text =
            Html.h1 [ class "text-layout-90 w-full text-4xl font-light leading-[1.1]" ]
                text

        title : Maybe (Html msg)
        title =
            case config.title of
                NoPageTitle ->
                    Nothing

                PageTitleOnly title_ ->
                    titleEl title_
                        |> Just

                PageTitleAndSubtitle title_ subtitle ->
                    Html.div [ class "flex flex-col gap-3" ]
                        [ titleEl title_
                        , Html.div [ class "text-sm" ]
                            [ subtitle ]
                        ]
                        |> Just

        aboutLink : Html msg
        aboutLink =
            if config.showAboutLink then
                Html.a [ href "/about" ]
                    [ Html.text "About" ]

            else
                Custom.Html.none

        header : Html msg
        header =
            case title of
                Nothing ->
                    Custom.Html.none

                Just title_ ->
                    Html.div [ class "p-2 pb-0 " ]
                        [ Html.header [ class "text-layout-50 bg-layout-20 flex w-full flex-col items-center rounded-lg" ]
                            [ Html.div [ class "mt-2 flex w-full flex-row items-center justify-end gap-4 px-4 text-sm", class pageMaxWidth ]
                                [ aboutLink
                                , viewFeedLinks config.rssFeed
                                , changeThemeButtonView config
                                ]
                            , Html.div [ class "w-full flex-grow px-4 pb-2", class pageMaxWidth ]
                                [ title_ ]
                            ]
                        ]

        content : Html msg
        content =
            Html.div [ class "flex w-full flex-col items-center" ]
                [ Html.main_ [ class "w-full px-4 pb-32 pt-6", class pageMaxWidth ]
                    [ config.content ]
                ]
    in
    Html.div [ class "text-layout-90 flex w-full flex-col" ]
        [ header
        , content
        ]
        |> Html.map PagesMsg.fromMsg


viewFeedLinks : Feeds msg -> Html msg
viewFeedLinks feed =
    case feed of
        FeedUrls { rssFeedUrl, atomFeedUrl } ->
            Html.div []
                [ Html.button
                    [ class "button gap-1 px-1 py-0.5"
                    , Custom.Html.Attributes.popoverTarget "feeds-list"
                    ]
                    [ Icon.rss Icon.Medium
                    , Html.text "Feeds"
                    ]
                , Html.div
                    [ Html.Attributes.id "feeds-list"
                    , Custom.Html.Attributes.popoverAuto
                    , class "border-layout-30 inset-auto mt-2 rounded border-2 px-4 py-3"
                    ]
                    [ Html.ul [ class "flex flex-col gap-2" ]
                        [ Html.li []
                            [ Html.a [ href atomFeedUrl ]
                                [ Html.text "Atom feed" ]
                            ]
                        , Html.li []
                            [ Html.a [ href rssFeedUrl ]
                                [ Html.text "RSS feed" ]
                            ]
                        ]
                    ]
                ]

        NoFeedsWithExplanation explanation ->
            let
                tooltipId =
                    "no-rss-feed-explanation"
            in
            Html.div [ class "group relative flex flex-col items-end" ]
                [ Html.div
                    [ ariaDescribedBy [ tooltipId ]
                    , class "flex cursor-help flex-row items-center gap-1"
                    ]
                    [ Html.text "No RSS feed"
                    , Icon.info Icon.Small
                    ]
                , Html.div
                    [ roleTooltip
                    , id tooltipId
                    , class "bg-layout-80 text-layout-30 w-max max-w-60 rounded p-3 text-xs leading-normal"
                    , class "pointer-events-none invisible absolute top-8 z-10 opacity-0 transition-all delay-100"
                    , class "group-hover:visible group-hover:opacity-100"
                    ]
                    [ Html.text explanation ]
                ]

        NoFeeds ->
            Custom.Html.none


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
        [ class "button size-6"
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
