module Page.Tag exposing (..)

import Browser.Navigation
import Custom.List as List
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Shared
import Site
import Url.Builder exposing (QueryParameter)
import View exposing (View)


page : PageWithState {} Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithSharedState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data {} -> ( Model, Cmd Msg )
init maybePageUrl sharedModel static =
    let
        queryTagSlugs =
            maybePageUrl
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "t")
                |> Maybe.withDefault []

        queryTags =
            static.sharedData.tags
                |> List.filter (.slug >> List.memberOf queryTagSlugs)
    in
    ( { queryTags = queryTags }, Cmd.none )



-- DATA


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()



-- UPDATE


type alias Model =
    { queryTags : List Tag
    }


type alias Msg =
    Never


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data {}
    -> Msg
    -> Model
    -> ( Model, Cmd Msg, Maybe Shared.Msg )
update pageUrl navKey sharedModel static msg model =
    ( model, Cmd.none, Nothing )



-- SUBSCRIPTIONS


subscriptions : Maybe PageUrl -> {} -> Path -> Model -> Shared.Model -> Sub Msg
subscriptions maybePageUrl _ path model sharedModel =
    Sub.none



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle "Tags"


head :
    StaticPayload Data {}
    -> List Head.Tag
head static =
    Site.meta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data {}
    -> View Msg
view maybeUrl sharedModel model static =
    let
        posts =
            static.sharedData.posts
                |> List.filter
                    (\post ->
                        model.queryTags
                            |> List.all (.slug >> List.memberOf post.frontmatter.tags)
                    )

        postViews =
            Data.PostList.view static.sharedData.categories posts

        subTags =
            posts
                |> List.andThen (.frontmatter >> .tags)
                |> List.unique
                |> List.map (Tag.get static.sharedData.tags)
                |> List.filter (List.memberOf model.queryTags >> not)

        tagToEl tag =
            case List.remove tag model.queryTags of
                otherTag1 :: otherTagsRest ->
                    Html.a
                        [ Attr.class "removable contrast"
                        , Attr.href (Tag.toUrl otherTag1 otherTagsRest)
                        , Attr.attribute "data-tooltip" "Remove from filter"
                        ]
                        [ Html.text tag.name ]

                [] ->
                    Html.text tag.name

        titleChildren =
            if List.length model.queryTags > 0 then
                [ Html.text "Tags: "
                , Html.em []
                    (model.queryTags
                        |> List.map tagToEl
                        |> List.intersperse (Html.text ", ")
                    )
                ]

            else
                [ Html.text "Tags" ]
    in
    { title = title static
    , body =
        [ Html.h1 []
            titleChildren
        , Html.div [ Attr.class "grid" ]
            [ Html.section []
                postViews
            , Html.section []
                [ Html.article []
                    [ Html.p []
                        (Tag.listView model.queryTags static.sharedData.posts subTags)
                    ]
                ]
            ]
        ]
    }
