module Page.Tag exposing (..)

import Browser.Navigation
import Data.Category as Category
import Data.Date as Date
import Data.Post as Post exposing (Post)
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Page exposing (Page, PageWithState, StaticPayload)
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
                |> List.filter (\t -> List.any ((==) t.slug) queryTagSlugs)
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
        tagInPost post tag =
            post.frontmatter.tags
                |> List.any ((==) tag.slug)

        posts =
            static.sharedData.posts
                |> List.filter
                    (\post ->
                        model.queryTags
                            |> List.all (tagInPost post)
                    )

        postViews =
            Data.PostList.view static.sharedData.categories posts
    in
    { title = title static
    , body =
        [ Html.h1 []
            [ Html.text "Tags" ]
        , Html.div [ Attr.class "grid" ]
            [ Html.section []
                postViews
            , Html.section []
                [ Html.article []
                    [ Html.p []
                        (Tag.listView static.sharedData.posts static.sharedData.tags)
                    ]
                ]
            ]
        ]
    }
