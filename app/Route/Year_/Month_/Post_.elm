module Route.Year_.Month_.Post_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Custom.Int as Int
import Data.Category as Category
import Data.Date
import Data.MastodonPost as MastodonPost exposing (MastodonPost)
import Data.Post as Post exposing (Post)
import Data.Tag as Tag
import Date
import Doc.FromMarkdown
import Doc.ToHtml
import Doc.ToPlainText
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Html.Attributes exposing (class, href, target)
import Html.Extra
import Http
import Maybe.Extra exposing (isJust)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.AudioPlayer
import View.CodeBlock
import View.PageBody


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildWithSharedState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init app shared =
    ( { audioPlayerState = View.AudioPlayer.initialState
      , mastodonPostRequest = MastodonPostRequesting
      }
    , case app.data.gist.mastodonPostId of
        Just id ->
            Effect.GetMastodonPost GotMastodonPost id

        Nothing ->
            Effect.none
    )



-- PAGES


type alias RouteParams =
    { year : String
    , month : String
    , post : String
    }


pages : BackendTask FatalError (List RouteParams)
pages =
    Post.gistsList
        |> BackendTask.map
            (List.map
                (\postGist ->
                    { year = Date.year postGist.date |> Int.padLeft 4
                    , month = Date.monthNumber postGist.date |> Int.padLeft 2
                    , post = postGist.slug
                    }
                )
            )



-- DATA


type alias Data =
    Post


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Post.singleDataSource
        routeParams.year
        routeParams.month
        routeParams.post
        |> BackendTask.allowFatal



-- UPDATE


type alias Model =
    { audioPlayerState : View.AudioPlayer.State
    , mastodonPostRequest : MastodonPostRequest
    }


type MastodonPostRequest
    = MastodonPostNotRequested
    | MastodonPostRequesting
    | MastodonPostObtained MastodonPost


type Msg
    = AudioPlayerStateUpdated View.AudioPlayer.State
    | GotMastodonPost (Result Http.Error MastodonPost)
    | SharedMsg Shared.Msg


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg, Maybe Shared.Msg )
update app shared msg model =
    case msg of
        AudioPlayerStateUpdated state ->
            ( { model | audioPlayerState = state }
            , Effect.none
            , Nothing
            )

        GotMastodonPost (Result.Err _) ->
            ( model, Effect.none, Nothing )

        GotMastodonPost (Result.Ok mastodonPost) ->
            ( { model | mastodonPostRequest = MastodonPostObtained mastodonPost }
            , Effect.none
            , Nothing
            )

        SharedMsg sharedMsg ->
            ( model, Effect.none, Just sharedMsg )



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none



-- VIEW


title : String -> String
title postTitle =
    Site.windowTitle postTitle


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    let
        contentSummary =
            app.data.markdown
                |> Doc.FromMarkdown.parse { audioPlayer = Nothing }
                |> Doc.ToPlainText.view
                |> String.lines
                |> List.filter ((/=) "")
                |> String.join " | "
                |> String.words
                |> List.take 30
                |> String.join " "
                |> String.left 200
                |> (\s -> s ++ "…")
    in
    Site.postMeta
        { title = title app.data.gist.title
        , description = contentSummary
        , publishedDate = app.data.gist.dateTime
        , tags = app.data.gist.tags
        , mainCategory =
            app.data.gist.categories
                |> List.head
        }


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    let
        date : String
        date =
            Data.Date.formatShortDate app.data.gist.date

        categoryEls : List (Html Msg)
        categoryEls =
            app.data.gist.categories
                |> List.map Category.toLink
                |> List.intersperse (Html.text ", ")

        categoriesTextEls : List (Html Msg)
        categoriesTextEls =
            if List.length app.data.gist.categories > 0 then
                [ Html.text "Categories: "
                , Html.i [] categoryEls
                , Html.text ". "
                ]

            else
                [ Html.text "No categories. " ]

        tagEls : List (Html Msg)
        tagEls =
            app.data.gist.tags
                |> List.map Tag.toLink
                |> List.intersperse (Html.text ", ")

        tagsTextEls : List (Html Msg)
        tagsTextEls =
            if List.length app.data.gist.tags > 0 then
                [ Html.text "Tags: "
                , Html.i [] tagEls
                , Html.text "."
                ]

            else
                [ Html.text "No tags." ]

        postInfo : Html Msg
        postInfo =
            Html.p [ class "w-full" ]
                ([ Html.text
                    ("Posted {date}, on "
                        |> String.replace "{date}" date
                    )
                 , Html.a [ href "/" ]
                    [ Html.text "agj's blog" ]
                 , Html.text ". "
                 ]
                    ++ categoriesTextEls
                    ++ tagsTextEls
                )

        contentEl : Html Msg
        contentEl =
            [ [ app.data.markdown
                    |> Doc.FromMarkdown.parse
                        { audioPlayer = Just { onAudioPlayerStateUpdated = AudioPlayerStateUpdated } }
                    |> Doc.ToHtml.view { audioPlayerState = Just model.audioPlayerState, onClick = Nothing }
              ]
            , case app.data.gist.mastodonPostId of
                Just mastodonPostId ->
                    [ Html.hr [ class "bg-layout-20 mb-8 mt-20 h-4 border-0" ] []
                    , viewReplies model.mastodonPostRequest mastodonPostId
                    ]

                Nothing ->
                    [ Html.Extra.nothing ]
            , [ View.CodeBlock.styles ]
            ]
                |> List.concat
                |> Html.div [ class "flex flex-col" ]
    in
    { title = title app.data.gist.title
    , body =
        View.PageBody.fromContent
            { theme = shared.theme
            , onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme
            }
            contentEl
            |> View.PageBody.withTitleAndSubtitle
                [ Html.text app.data.gist.title ]
                postInfo
            |> View.PageBody.view
    }


viewReplies : MastodonPostRequest -> String -> Html Msg
viewReplies mastodonPostRequest mastodonPostId =
    let
        replies =
            case mastodonPostRequest of
                MastodonPostObtained mastodonPost ->
                    mastodonPost.replies

                _ ->
                    0

        message =
            case replies of
                0 ->
                    [ Html.p []
                        [ Html.a
                            [ href (MastodonPost.idToUrl mastodonPostId)
                            , target "_blank"
                            ]
                            [ Html.text "Comment over at Mastodon" ]
                        ]
                    ]

                _ ->
                    [ Html.p []
                        [ Html.a
                            [ href (MastodonPost.idToUrl mastodonPostId)
                            , target "_blank"
                            ]
                            [ Html.b [] [ Html.text (String.fromInt replies) ]
                            , Html.text
                                " replies over at Mastodon."
                            ]
                        ]
                    ]
    in
    Html.section [] message
