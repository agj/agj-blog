module Route.Category.Category_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Data.Category as Category exposing (Category)
import Data.PostList
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.PageBody
import View.Snippets


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
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
    ( {}, Effect.none )



-- ROUTES


type alias RouteParams =
    { category : String }


pages : BackendTask FatalError (List RouteParams)
pages =
    Category.all
        |> List.map Category.getSlug
        |> List.map (\slug -> { category = slug })
        |> BackendTask.succeed



-- DATA


type alias Data =
    Category


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Category.singleDataSource routeParams.category
        |> BackendTask.mapError FatalError.fromString



-- UPDATE


type alias Model =
    {}


type Msg
    = SharedMsg Shared.Msg


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


title : App Data ActionData RouteParams -> String
title app =
    "Category: {category}"
        |> String.replace "{category}" app.routeParams.category
        |> Site.windowTitle


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.pageMeta (title app)


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    let
        category =
            app.data

        posts =
            app.sharedData.posts
                |> List.filter (.frontmatter >> .categories >> List.member category)

        titleEls : List (Html Msg)
        titleEls =
            [ Html.text "Category: "
            , Html.i [] [ Html.text (Category.getName category) ]
            ]

        categoryDescription : List (Html Msg)
        categoryDescription =
            Category.getDescription category
                |> Maybe.map
                    (\desc -> [ Html.text (desc ++ " ") ])
                |> Maybe.withDefault []

        subtitle : Html Msg
        subtitle =
            Html.p []
                (categoryDescription
                    ++ View.Snippets.backToIndex
                )

        content =
            Data.PostList.view posts
    in
    { title = title app
    , body =
        View.PageBody.fromContent
            { onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme }
            content
            |> View.PageBody.withTitleAndSubtitle titleEls subtitle
            |> View.PageBody.view
    }
