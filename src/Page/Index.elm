module Page.Index exposing (Data, Model, Msg, page)

import Browser.Navigation
import Data.Category as Category exposing (Category, NestedCategory)
import Data.Post as Post
import Data.PostList
import Data.Tag as Tag
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Shared
import Site
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
        maybeRequestedPostId =
            maybePageUrl
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "p")
                |> Maybe.andThen List.head
                |> Maybe.andThen String.toInt

        findPostGistById id =
            static.sharedData.posts
                |> List.find (\pg -> pg.frontmatter.id == Just id)

        maybePostRedirectCommand =
            maybeRequestedPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map postGistToUrl
                |> Maybe.map Browser.Navigation.load
    in
    ( {}
    , maybePostRedirectCommand
        |> Maybe.withDefault Cmd.none
    )



-- DATA


type alias Data =
    {}


data : DataSource Data
data =
    DataSource.succeed {}



-- UPDATE


type alias Model =
    {}


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
    ( {}, Cmd.none, Nothing )



-- SUBSCRIPTIONS


subscriptions : Maybe PageUrl -> {} -> Path -> Model -> Shared.Model -> Sub Msg
subscriptions maybePageUrl _ path model sharedModel =
    Sub.none



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle "Home"


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
    { title = title static
    , body =
        [ Html.div [ Attr.class "grid" ]
            [ Html.section []
                (Data.PostList.view
                    static.sharedData.categories
                    static.sharedData.posts
                )
            , Html.section []
                [ Html.article []
                    [ Html.h3 []
                        [ Html.text "Categories" ]
                    , Category.viewList static.sharedData.categories
                    ]
                , Html.article []
                    [ Html.h3 []
                        [ Html.text "Tags" ]
                    , Html.p []
                        (Tag.listView static.sharedData.posts static.sharedData.tags)
                    ]
                ]
            ]
        ]
    }



-- UTILITIES


postGistToUrl : Post.GlobMatchFrontmatter -> String
postGistToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" gist.year
        |> String.replace "{month}" gist.month
        |> String.replace "{post}" gist.post
