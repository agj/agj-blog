module Page.Category.Category_ exposing (Data, Model, Msg, page)

import Data.Category as Category exposing (Category)
import DataSource exposing (DataSource)
import DataSource.File
import Head
import Html
import List.Extra as List
import OptimizedDecoder as Decode exposing (Decoder)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)
import Yaml.Decode


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { category : String }


routes : DataSource (List RouteParams)
routes =
    Category.dataSource
        |> DataSource.map (List.map (\{ slug } -> { category = slug }))



-- DATA


type alias Data =
    ()


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.succeed ()



-- VIEW


title : StaticPayload Data RouteParams -> String
title static =
    "Category: {category}"
        |> String.replace "{category}" static.routeParams.category
        |> Site.windowTitle


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Site.meta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        category =
            Category.get static.sharedData.categories static.routeParams.category
    in
    { title = title static
    , body =
        [ Html.h1 []
            [ Html.text "Category: "
            , Html.em []
                [ Html.text category.name ]
            ]
        ]
    }
