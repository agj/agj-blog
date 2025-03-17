module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Browser.Navigation
import Data.Category as Category
import Data.Post as Post
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
import View.Column exposing (Spacing(..))
import View.Heading
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
        maybeRequestedPostId =
            app.url
                |> Maybe.map .query
                |> Maybe.andThen (Dict.get "p")
                |> Maybe.andThen List.head
                |> Maybe.andThen String.toInt

        maybeUrlFragment =
            app.url
                |> Maybe.andThen .fragment

        findPostGistById id =
            app.sharedData.posts
                |> List.find (\pg -> pg.frontmatter.id == Just id)

        maybePostRedirectCommand =
            maybeRequestedPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map Post.globMatchFrontmatterToUrl
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
    , maybePostRedirectCommand
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


type alias Msg =
    Never


type alias RouteParams =
    {}


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg, Maybe Shared.Msg )
update app shared msg model =
    ( {}, Effect.none, Nothing )



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
            , [ [ Html.text "Categories" ]
                    |> View.Heading.view 2
              , Category.viewList
              , [ Html.text "Tags" ]
                    |> View.Heading.view 2
              , Tag.listView Nothing [] app.sharedData.posts Tag.all
              ]
                |> View.Column.setSpaced MSpacing
            ]

        content : Html Msg
        content =
            Html.div [ class "grid grid-cols-2 gap-5" ]
                cols
    in
    { title = title
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitle
                [ Html.text "agj's blog" ]
            |> View.PageBody.view
    }
