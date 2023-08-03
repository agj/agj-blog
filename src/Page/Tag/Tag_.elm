module Page.Tag.Tag_ exposing (..)

import Data.Tag as Tag
import DataSource exposing (DataSource)
import Head
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import View exposing (View)


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState
            { view = view
            }


type alias Model =
    ()


type alias Msg =
    Never



-- ROUTES


type alias RouteParams =
    { tag : String }


routes : DataSource (List RouteParams)
routes =
    Tag.all
        |> List.map Tag.getSlug
        |> List.map (\slug -> { tag = slug })
        |> DataSource.succeed



-- DATA


type alias Data =
    ()


data : RouteParams -> DataSource Data
data _ =
    DataSource.succeed ()



-- VIEW


title : StaticPayload Data RouteParams -> String
title static =
    ""


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    [ Head.metaRedirect
        (Head.raw
            ("0; url="
                ++ Tag.slugsToUrl static.routeParams.tag []
            )
        )
    ]


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = title static
    , body =
        []
    }
