module Route.Tag exposing (ActionData, Data, Model, Msg, route)

import AppUrl exposing (AppUrl)
import BackendTask exposing (BackendTask)
import Custom.Html
import Custom.List as List
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import Dict exposing (Dict)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Html.Events
import List.Extra as List
import PagesMsg exposing (PagesMsg)
import Result.Extra as Result
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import Url
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.PageBody
import View.Snippets


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
        query : Dict String (List String)
        query =
            app.url
                |> Maybe.map .query
                |> Maybe.withDefault Dict.empty
    in
    ( { queryTags = queryTags query }
    , Effect.none
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
    { queryTags : List Tag
    }


type Msg
    = OnClick String
    | SharedMsg Shared.Msg


type alias RouteParams =
    {}


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg, Maybe Shared.Msg )
update app shared msg model =
    case msg of
        OnClick urlString ->
            let
                urlMaybe : Maybe AppUrl
                urlMaybe =
                    -- Plain paths don't get parsed, so we need to add something on the front.
                    Url.fromString ("http://x.x" ++ urlString)
                        |> Maybe.map AppUrl.fromUrl
            in
            case urlMaybe of
                Just url ->
                    ( { model | queryTags = queryTags url.queryParameters }
                    , Effect.none
                    , Nothing
                    )

                Nothing ->
                    ( model, Effect.none, Nothing )

        SharedMsg sharedMsg ->
            ( model, Effect.none, Just sharedMsg )


queryTags : Dict String (List String) -> List Tag
queryTags query =
    query
        |> Dict.get "t"
        |> Maybe.withDefault []
        |> List.map Tag.fromSlug
        |> List.filter Result.isOk
        |> Result.combine
        |> Result.withDefault []



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

        tagToEl : Tag -> Html Msg
        tagToEl tag =
            let
                url =
                    case List.remove tag model.queryTags of
                        otherTag1 :: otherTagsRest ->
                            Tag.toUrl otherTag1 otherTagsRest

                        [] ->
                            Tag.baseUrl
            in
            Html.a [ href url, Html.Events.onClick (OnClick url) ]
                [ Html.text (Tag.getName tag) ]

        titleChildren : List (Html Msg)
        titleChildren =
            if List.length model.queryTags > 0 then
                [ Html.text "Tags: "
                , (model.queryTags
                    |> List.map tagToEl
                    |> List.intersperse (Html.text ", ")
                  )
                    |> Html.i []
                ]

            else
                [ Html.text "Tags" ]

        subtitle : Html Msg
        subtitle =
            Html.p []
                View.Snippets.backToIndex

        postColumn : Html Msg
        postColumn =
            if List.length model.queryTags > 0 then
                postViews

            else
                Custom.Html.none

        tagsColumn : Html Msg
        tagsColumn =
            Tag.listView (Just OnClick) model.queryTags app.sharedData.posts subTags

        content =
            Html.div [ class "grid grid-cols-2 gap-4" ]
                [ postColumn
                , tagsColumn
                ]
    in
    { title = title
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withListener { onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme }
            |> View.PageBody.withTitleAndSubtitle titleChildren subtitle
            |> View.PageBody.view
    }
