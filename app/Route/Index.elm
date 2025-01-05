module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Browser.Navigation
import Custom.Element as Ui
import Data.Category as Category exposing (Category, NestedCategory)
import Data.Post as Post
import Data.PostList
import Data.Tag as Tag
import Dict exposing (Dict)
import Effect exposing (Effect)
import Element as Ui
import FatalError exposing (FatalError)
import Head
import List.Extra as List
import Maybe.Extra as Maybe
import Pages.PageUrl exposing (PageUrl)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Sand
import Shared
import Site
import Style
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
        cols =
            [ Data.PostList.view app.sharedData.posts
                |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]
            , [ [ Ui.text "Categories" ]
                    |> View.Heading.view 2
              , Category.viewList
              , [ Ui.text "Tags" ]
                    |> View.Heading.view 2
              , Tag.listView Nothing [] app.sharedData.posts Tag.all
              ]
                |> View.Column.setSpaced MSpacing
                |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]
            ]
                |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])

        content =
            Sand.gridCols
                { cols = Sand.ResponsiveGridCols [ ( 0, [ Sand.GlFraction 2, Sand.GlFraction 1 ] ), ( 500, [ Sand.GlFraction 1 ] ) ]
                , gap = Sand.L4
                }
                cols
                |> Ui.html
    in
    { title = title
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitle
                [ Ui.text "agj's blog" ]
            |> View.PageBody.view
    }
