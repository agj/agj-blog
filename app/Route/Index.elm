module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Browser.Navigation
import Consts
import Custom.Html.Attributes exposing (ariaPressed)
import Custom.Markdown
import Data.AtomFeed as AtomFeed
import Data.Category as Category
import Data.Language as Language
import Data.Post as Post exposing (PostGist)
import Data.PostList exposing (PostGistWithSummary)
import Data.Tag as Tag
import Dict
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Html.Events
import List.Extra as List
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.PageBody


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildWithSharedState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init app shared =
    let
        maybeRequestedPostId : Maybe Int
        maybeRequestedPostId =
            app.url
                |> Maybe.map .query
                |> Maybe.andThen (Dict.get "p")
                |> Maybe.andThen List.head
                |> Maybe.andThen String.toInt

        maybeUrlFragment : Maybe String
        maybeUrlFragment =
            app.url
                |> Maybe.andThen .fragment

        findPostGistById : Int -> Maybe PostGist
        findPostGistById id =
            app.sharedData.posts
                |> List.find (\post -> post.id == Just id)

        maybePostRedirectCmd : Maybe (Cmd msg)
        maybePostRedirectCmd =
            maybeRequestedPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map Post.gistToUrl
                |> Maybe.map
                    (\url ->
                        case maybeUrlFragment of
                            Just fragment ->
                                url ++ "#" ++ fragment

                            Nothing ->
                                url
                    )
                |> Maybe.map Browser.Navigation.load
    in
    ( {}
    , maybePostRedirectCmd
        |> Maybe.withDefault Cmd.none
        |> Effect.fromCmd
    )



-- DATA


type alias Data =
    { postsWithSummary : List { gist : PostGist, summary : String }
    }


type alias ActionData =
    {}


data : BackendTask FatalError Data
data =
    Post.list
        |> BackendTask.map
            (\posts ->
                posts
                    |> List.take 10
                    |> List.map
                        (\{ gist, markdown } ->
                            { gist = gist, summary = Custom.Markdown.getSummary markdown }
                        )
                    |> Data
            )



-- UPDATE


type alias Model =
    {}


type Msg
    = SharedMsg Shared.Msg


type alias RouteParams =
    {}


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg, Maybe Shared.Msg )
update app shared msg model =
    case msg of
        SharedMsg sharedMsg ->
            ( model, Effect.none, Just sharedMsg )



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub msg
subscriptions routeParams path shared model =
    Sub.none



-- VIEW


title : String
title =
    Consts.siteName


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.pageMeta title
        ++ [ Head.rssLink feedUrls.rssUrl
           , AtomFeed.linkNode feedUrls.atomUrl
           ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    let
        postsWithSummary : List PostGistWithSummary
        postsWithSummary =
            app.data.postsWithSummary
                |> List.map (\{ gist, summary } -> { gist = gist, summary = Just summary })

        restPosts : List PostGistWithSummary
        restPosts =
            app.sharedData.posts
                |> List.drop (List.length postsWithSummary)
                |> List.map (\p -> { gist = p, summary = Nothing })

        posts : List PostGistWithSummary
        posts =
            postsWithSummary ++ restPosts

        -- Sanity check to make sure the two separate lists of posts
        -- with and without a summary have the same posts.
        postListsAreMatched : Bool
        postListsAreMatched =
            List.zip posts app.sharedData.posts
                |> List.all
                    (\( postWithSummary, postNoSummary ) ->
                        (postWithSummary.gist.dateTime == postNoSummary.dateTime)
                            && (postWithSummary.gist.slug == postNoSummary.slug)
                    )

        languageButton language =
            let
                isSelected =
                    List.member language shared.languages

                noneSelected =
                    shared.languages == []

                newLanguagesOnClick =
                    if isSelected then
                        List.remove language shared.languages

                    else
                        language :: shared.languages
            in
            Html.button
                [ class "rounded-sm px-1 text-xs"
                , if noneSelected then
                    class "bg-layout-60 text-layout-10"

                  else
                    class "bg-layout-30 text-layout-10 aria-pressed:no-underline line-through decoration-layout-50 aria-pressed:bg-layout-90 decoration-2"
                , ariaPressed isSelected
                , Html.Events.onClick (SharedMsg (Shared.ChangedLanguages newLanguagesOnClick))
                ]
                [ Html.text (Language.toShortString language |> String.toUpper) ]

        languagesView =
            Html.ul [ class "flex flex-row gap-1" ]
                (Language.all
                    |> List.map
                        (\language -> Html.li [] [ languageButton language ])
                )

        content : Html Msg
        content =
            if not postListsAreMatched then
                Html.text """
                    POST LISTS ARE UNMATCHED!
                    The lists of posts with a summary is not the
                    same as the list of posts without a summary.
                    It's necessary that these two lists match the
                    same posts in the same order, so that we can use
                    `List.take`/`List.drop` on them to combine them,
                    and still get the same list of posts.
                """

            else
                Html.div
                    [ class "grid gap-x-5 gap-y-8"
                    , class "md:grid-cols-4"
                    ]
                    [ -- Categories and tags.
                      Html.div
                        [ class "grid gap-x-5 gap-y-8"
                        , class "sm:grid-cols-[1fr_2fr]"
                        , class "md:order-last md:flex md:flex-col md:gap-5"
                        ]
                        [ -- Languages.
                          Html.div []
                            [ Html.h2 [ class "text-layout-70 text-2xl" ]
                                [ Html.text "Language" ]
                            , languagesView
                            ]

                        -- Categories.
                        , Html.div [ class "flex flex-col gap-4" ]
                            [ Html.h2 [ class "text-layout-70 text-2xl" ]
                                [ Html.text "Categories" ]
                            , Category.viewList
                            ]

                        -- Tags.
                        , Html.div [ class "flex flex-col gap-4" ]
                            [ Html.h2 [ class "text-layout-70 text-2xl" ]
                                [ Html.a [ href "/tag" ]
                                    [ Html.text "Tags" ]
                                ]
                            , Html.ul
                                [ class "flex flex-row flex-wrap gap-x-2 text-sm leading-relaxed"
                                , class "md:block"
                                ]
                                (List.concat
                                    [ Tag.listViewShort 20 app.sharedData.posts Tag.all
                                        |> List.map (\el -> Html.li [] [ el ])
                                    , [ Html.li []
                                            [ Html.a
                                                [ href "/tag"
                                                , class "text-layout-50"
                                                ]
                                                [ Html.text "all other tags…" ]
                                            ]
                                      ]
                                    ]
                                )
                            ]
                        ]

                    -- Posts.
                    , Html.div
                        [ class "md:col-span-3" ]
                        [ Data.PostList.viewGists posts
                        ]
                    ]
    in
    { title = title
    , body =
        View.PageBody.fromContent
            { theme = shared.theme
            , onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme
            }
            content
            |> View.PageBody.withTitle
                [ Html.text title ]
            |> View.PageBody.withFeeds
                (View.PageBody.FeedUrls
                    { rssFeedUrl = feedUrls.rssUrl
                    , atomFeedUrl = feedUrls.atomUrl
                    }
                )
            |> View.PageBody.view
    }


feedUrls : { rssUrl : String, atomUrl : String }
feedUrls =
    { rssUrl = "/rss.xml"
    , atomUrl = "/atom.xml"
    }
