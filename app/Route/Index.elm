module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Browser.Navigation
import Data.Category as Category
import Data.Post as Post exposing (PostGist)
import Data.PostList
import Data.Tag as Tag
import Dict
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Html.Attributes exposing (class)
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
    {}


type alias ActionData =
    {}


data : BackendTask FatalError Data
data =
    BackendTask.succeed {}



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
    Site.windowTitle "Home"


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.pageMeta title
        ++ [ Head.rssLink "/rss.xml" ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    let
        cols : List (Html Msg)
        cols =
            [ Data.PostList.view app.sharedData.posts
            , Html.div [ class "flex flex-col" ]
                [ Html.h2 [ class "text-2xl" ]
                    [ Html.text "Categories" ]
                , Category.viewList
                , Html.h2 [ class "mt-4 text-2xl" ]
                    [ Html.text "Tags" ]
                , Html.p [ class "text-sm" ]
                    (Tag.listView Nothing [] app.sharedData.posts Tag.all)
                ]
            ]

        content : Html Msg
        content =
            Html.div [ class "grid grid-cols-2 gap-5" ]
                cols
    in
    { title = title
    , body =
        View.PageBody.fromContent
            { theme = shared.theme
            , onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme
            }
            content
            |> View.PageBody.withTitle
                [ Html.text "agj's blog" ]
            |> View.PageBody.withRssFeed (View.PageBody.RssFeedUrl "/rss.xml")
            |> View.PageBody.view
    }
