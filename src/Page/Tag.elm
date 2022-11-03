module Page.Tag exposing (..)

import Data.Category as Category
import Data.Date as Date
import Data.Post as Post exposing (Post)
import Data.Tag as Tag
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import QueryParams exposing (QueryParams)
import Shared
import Site
import Url.Builder exposing (QueryParameter)
import View exposing (View)


page : Page {} Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


type alias Model =
    ()


type alias Msg =
    Never



-- DATA


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()



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
    -> StaticPayload Data {}
    -> View Msg
view maybeUrl sharedModel static =
    let
        tags =
            maybeUrl
                |> Debug.log "url"
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "t")
                |> Debug.log "tags"
    in
    { title = title static
    , body =
        [ Html.h1 []
            [ Html.text "Tags" ]
        , Html.p []
            (Tag.listView static.sharedData.posts static.sharedData.tags)
        ]
    }
