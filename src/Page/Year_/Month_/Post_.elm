module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import Data.Category as Category
import Data.Date as Date
import Data.PageHeader as PageHeader
import Data.Post as Post exposing (Post)
import Data.Tag as Tag
import DataSource exposing (DataSource)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
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
            Date.formatShortDate
                static.routeParams.year
                (String.toInt static.routeParams.month |> Maybe.withDefault 0)
                static.data.frontmatter.date

        categoryEls =
            static.data.frontmatter.categories
                |> List.map (Category.toLink [])
                |> List.intersperse (Html.text ", ")

        categoriesTextEls =
            if List.length static.data.frontmatter.categories > 0 then
                [ Html.text "Categories: "
                , Html.em [] categoryEls
                , Html.text ". "
                ]

            else
                [ Html.text "No categories. " ]

        tagEls =
            static.data.frontmatter.tags
                |> List.map (Tag.get static.sharedData.tags)
                |> List.map (Tag.toLink [] [])
                |> List.intersperse (Html.text ", ")

        tagsTextEls =
            if List.length static.data.frontmatter.tags > 0 then
                [ Html.text "Tags: "
                , Html.em [] tagEls
                , Html.text "."
                ]

            else
                [ Html.text "No tags." ]
    in
    { title = title static
    , body =
        PageHeader.view
            [ Html.text static.data.frontmatter.title ]
            (Just
                (Html.p []
                    [ Html.small []
                        ([ Html.text ("Posted {date}, on " |> String.replace "{date}" date)
                         , Html.a [ Attr.href "/" ]
                            [ Html.text "agj's blog" ]
                         , Html.text ". "
                         ]
                            ++ categoriesTextEls
                            ++ tagsTextEls
                        )
                    ]
                )
            )
            :: static.data.content
    }
