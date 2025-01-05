module Route.Tag exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Custom.Element as Ui
import Custom.List as List
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Element as Ui
import FatalError exposing (FatalError)
import Head
import List.Extra as List
import PagesMsg exposing (PagesMsg)
import Result.Extra as Result
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import Style
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init app shared =
    let
        queryTags =
            app.url
                |> Maybe.map .query
                |> Maybe.andThen (Dict.get "t")
                |> Maybe.withDefault []
                |> List.map Tag.fromSlug
                |> List.filter Result.isOk
                |> Result.combine
                |> Result.withDefault []
    in
    ( { queryTags = queryTags }, Effect.none )



-- PAGES


type alias RouteParams =
    {}



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
    { queryTags : List Tag
    }


type alias Msg =
    ()


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update app shared msg model =
    ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none



-- VIEW


title : String
title =
    Site.windowTitle "Tags"


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
        posts =
            app.sharedData.posts
                |> List.filter
                    (\post ->
                        model.queryTags
                            |> List.all (List.memberOf post.frontmatter.tags)
                    )

        postViews =
            Data.PostList.view posts

        subTags =
            posts
                |> List.andThen (.frontmatter >> .tags)
                |> List.unique
                |> List.filter (List.memberOf model.queryTags >> not)

        tagToEl tag =
            let
                url =
                    case List.remove tag model.queryTags of
                        otherTag1 :: otherTagsRest ->
                            Tag.toUrl otherTag1 otherTagsRest

                        [] ->
                            Tag.baseUrl
            in
            [ Ui.text (Tag.getName tag) ]
                |> View.Inline.setLink Nothing url

        titleChildren =
            if List.length model.queryTags > 0 then
                [ Ui.text "Tags: "
                , (model.queryTags
                    |> List.map tagToEl
                    |> List.intersperse (Ui.text ", ")
                  )
                    |> View.Inline.setItalic
                ]

            else
                [ Ui.text "Tags" ]

        subtitle =
            [ Ui.text "Back to "
            , [ Ui.text "the index" ]
                |> View.Inline.setLink Nothing "/"
            , Ui.text "."
            ]
                |> View.Paragraph.view

        postColumn =
            if List.length model.queryTags > 0 then
                postViews
                    |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]

            else
                Ui.none

        tagsColumn =
            Tag.listView model.queryTags app.sharedData.posts subTags
                |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]

        content =
            [ postColumn
            , tagsColumn
            ]
                |> Ui.row
                    [ Ui.width Ui.fill
                    , Ui.varSpacing Style.spacing.size5
                    ]
    in
    { title = title
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleChildren subtitle
            |> View.PageBody.view
    }
