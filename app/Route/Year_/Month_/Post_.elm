module Route.Year_.Month_.Post_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Data.Category as Category
import Data.Date
import Data.Post as Post exposing (Post)
import Data.Tag as Tag
import Date
import Doc.Html
import Doc.Markdown
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Html.Attributes exposing (class)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.AudioPlayer
import View.CodeBlock
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init app shared =
    ( { audioPlayerState = View.AudioPlayer.initialState }
    , Effect.none
    )



-- PAGES


type alias RouteParams =
    { year : String
    , month : String
    , post : String
    }


pages : BackendTask FatalError (List RouteParams)
pages =
    Post.listDataSource
        |> BackendTask.map
            (List.map
                (\match ->
                    { year = match.year
                    , month = match.month
                    , post = match.post
                    }
                )
            )
        |> BackendTask.allowFatal



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
    { audioPlayerState : View.AudioPlayer.State }


type Msg
    = AudioPlayerStateUpdated View.AudioPlayer.State


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update app shared msg model =
    case msg of
        AudioPlayerStateUpdated state ->
            ( { audioPlayerState = state }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none



-- VIEW


title : App Data ActionData RouteParams -> String
title static =
    Site.windowTitle static.data.frontmatter.title


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.postMeta
        { title = title app
        , publishedDate =
            Date.fromCalendarDate
                (String.toInt app.routeParams.year |> Maybe.withDefault 1990)
                (String.toInt app.routeParams.month |> Maybe.withDefault 1 |> Date.numberToMonth)
                app.data.frontmatter.date
        , tags = app.data.frontmatter.tags
        , mainCategory =
            app.data.frontmatter.categories
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
            Data.Date.formatShortDate
                app.routeParams.year
                (String.toInt app.routeParams.month |> Maybe.withDefault 0)
                app.data.frontmatter.date

        categoryEls : List (Html Msg)
        categoryEls =
            app.data.frontmatter.categories
                |> List.map Category.toLink
                |> List.intersperse (Html.text ", ")

        categoriesTextEls : List (Html Msg)
        categoriesTextEls =
            if List.length app.data.frontmatter.categories > 0 then
                [ Html.text "Categories: "
                , Html.i [] categoryEls
                , Html.text ". "
                ]

            else
                [ Html.text "No categories. " ]

        tagEls : List (Html Msg)
        tagEls =
            app.data.frontmatter.tags
                |> List.map (Tag.toLink Nothing [])
                |> List.intersperse (Html.text ", ")

        tagsTextEls : List (Html Msg)
        tagsTextEls =
            if List.length app.data.frontmatter.tags > 0 then
                [ Html.text "Tags: "
                , Html.i [] tagEls
                , Html.text "."
                ]

            else
                [ Html.text "No tags." ]

        postInfo : Html Msg
        postInfo =
            Html.p [ class "w-full py-2" ]
                ([ Html.text ("Posted {date}, on " |> String.replace "{date}" date)
                 , View.Inline.setLink Nothing "/" [ Html.text "agj's blog" ]
                 , Html.text ". "
                 ]
                    ++ categoriesTextEls
                    ++ tagsTextEls
                )

        contentEl : Html Msg
        contentEl =
            [ app.data.markdown
                |> Doc.Markdown.parse
                    { audioPlayer = Just { onAudioPlayerStateUpdated = AudioPlayerStateUpdated } }
                |> Doc.Html.view { audioPlayerState = Just model.audioPlayerState, onClick = Nothing }
            , View.CodeBlock.styles
            ]
                |> Html.div [ class "flex flex-col" ]
    in
    { title = title app
    , body =
        View.PageBody.fromContent contentEl
            |> View.PageBody.withTitleAndSubtitle
                [ Html.text app.data.frontmatter.title ]
                postInfo
            |> View.PageBody.view
    }
