module Page.Category.Category_ exposing (Data, Model, Msg, page)

import Data.Category as Category exposing (Category)
import Data.PageHeader as PageHeader
import Data.PostList
import DataSource exposing (DataSource)
import Head
import Html
import Html.Attributes as Attr
import List.Extra as List
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



-- ROUTES


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

        posts =
            static.sharedData.posts
                |> List.filter (.frontmatter >> .categories >> List.member category.slug)

        postViews =
            Data.PostList.view static.sharedData.categories posts

        titleEl =
            [ Html.text "Category: "
            , Html.em []
                [ Html.text category.name ]
            ]

        backToIndexEls =
            [ Html.text "Back to "
            , Html.a [ Attr.href "/" ] [ Html.text "the index" ]
            , Html.text "."
            ]

        descriptionEl =
            category.description
                |> Maybe.map
                    (\desc -> Html.text (desc ++ " ") :: backToIndexEls)
                |> Maybe.withDefault backToIndexEls
                |> Html.p []
    in
    { title = title static
    , body =
        PageHeader.view titleEl (Just descriptionEl)
            :: postViews
    }
