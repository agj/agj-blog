module Route.Tag exposing (ActionData, Data, Model, Msg, route)

import AppUrl exposing (AppUrl, QueryParameters)
import BackendTask exposing (BackendTask)
import Custom.List as List
import Data.Post exposing (PostGist)
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
import Ports
import Result.Extra as Result
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import Url
import UrlPath exposing (UrlPath)
import View exposing (View)
import View.PageBody exposing (PageBody)
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
    ( { queryTags = getTagsFromQueryParams query }
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
    | QueryParamsChanged QueryParameters
    | SharedMsg Shared.Msg
    | NoOp


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
                    ( { model | queryTags = getTagsFromQueryParams url.queryParameters }
                    , Effect.none
                    , Nothing
                    )

                Nothing ->
                    ( model, Effect.none, Nothing )

        QueryParamsChanged queryParams ->
            ( { model | queryTags = getTagsFromQueryParams queryParams }
            , Effect.none
            , Nothing
            )

        SharedMsg sharedMsg ->
            ( model, Effect.none, Just sharedMsg )

        NoOp ->
            ( model, Effect.none, Nothing )


getTagsFromQueryParams : Dict String (List String) -> List Tag
getTagsFromQueryParams queryParams =
    queryParams
        |> Dict.get "t"
        |> Maybe.withDefault []
        |> List.map Tag.fromSlug
        |> List.filter Result.isOk
        |> Result.combine
        |> Result.withDefault []



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Ports.listenQueryParamsChanges QueryParamsChanged NoOp



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
        posts : List PostGist
        posts =
            app.sharedData.posts
                |> List.filter
                    (\post ->
                        model.queryTags
                            |> List.all (List.memberOf post.tags)
                    )

        subTags : List Tag
        subTags =
            posts
                |> List.andThen .tags
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
            Html.a
                [ href url
                , Html.Events.onClick (OnClick url)
                , class "hover:line-through"
                ]
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

        showPosts : Bool
        showPosts =
            List.length model.queryTags > 0

        tagsColumn : Html Msg
        tagsColumn =
            Html.ul [ class "flex flex-row flex-wrap content-start gap-x-2 text-sm" ]
                (Tag.listView
                    { onClick = Just OnClick
                    , selectedTags = model.queryTags
                    , posts = app.sharedData.posts
                    }
                    subTags
                    |> List.map (\el -> Html.li [ class "max-w-full" ] [ el ])
                )

        content : Html Msg
        content =
            if showPosts then
                Html.div [ class "grid grid-cols-2 gap-4" ]
                    [ Data.PostList.view posts
                    , tagsColumn
                    ]

            else
                Html.div []
                    [ tagsColumn ]

        withRssFeedLinkMaybe : PageBody Msg -> PageBody Msg
        withRssFeedLinkMaybe pageBody =
            case rssUrl model.queryTags of
                Just url ->
                    pageBody
                        |> View.PageBody.withRssFeed (View.PageBody.RssFeedUrl url)

                Nothing ->
                    pageBody
                        |> View.PageBody.withRssFeed
                            (View.PageBody.NoRssFeedWithExplanation
                                "RSS feeds are available for single tags only. You currently have multiple tags selected."
                            )
    in
    { title = title
    , body =
        View.PageBody.fromContent
            { theme = shared.theme
            , onRequestedChangeTheme = SharedMsg Shared.SelectedChangeTheme
            }
            content
            |> View.PageBody.withTitleAndSubtitle titleChildren subtitle
            |> withRssFeedLinkMaybe
            |> View.PageBody.view
    }


rssUrl : List Tag -> Maybe String
rssUrl tags =
    case tags of
        [ tag ] ->
            "/tag/{tagSlug}/rss.xml"
                |> String.replace "{tagSlug}" (Tag.getSlug tag)
                |> Just

        _ ->
            Nothing
