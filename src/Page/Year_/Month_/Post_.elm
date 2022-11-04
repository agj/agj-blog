module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import Data.Category as Category
import Data.Date as Date
import Data.Post as Post exposing (Post)
import DataSource exposing (DataSource)
import Head
import Html exposing (Html)
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)


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
    { year : String
    , month : String
    , post : String
    }


routes : DataSource (List RouteParams)
routes =
    Post.listDataSource
        |> DataSource.map
            (List.map
                (\match ->
                    { year = match.year
                    , month = match.month
                    , post = match.post
                    }
                )
            )



-- DATA


type alias Data =
    Post Msg


data : RouteParams -> DataSource Data
data routeParams =
    Post.singleDataSource routeParams.year routeParams.month routeParams.post



-- VIEW


title : StaticPayload Data RouteParams -> String
title static =
    Site.windowTitle static.data.frontmatter.title


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
        date =
            "{year} {month} {date}"
                |> String.replace "{year}" static.routeParams.year
                |> String.replace "{month}" (Date.monthNumberToShortName (String.toInt static.routeParams.month |> Maybe.withDefault 0))
                |> String.replace "{date}" (String.fromInt static.data.frontmatter.date)

        categoryEls =
            static.data.frontmatter.categories
                |> List.map (Category.get static.sharedData.categories)
                |> List.map (Category.toLink [])
                |> List.intersperse (Html.text ", ")
    in
    { title = title static
    , body =
        Html.node "hgroup"
            []
            [ Html.h1 []
                [ Html.text static.data.frontmatter.title ]
            , Html.p []
                [ Html.small []
                    [ Html.text
                        (date
                            ++ ". Categories: "
                        )
                    , Html.em [] categoryEls
                    , Html.text ". Tags: "
                    , Html.em []
                        [ Html.text (String.join ", " static.data.frontmatter.tags) ]
                    , Html.text "."
                    ]
                ]
            ]
            :: static.data.content
    }
