module Page.Category.Category_ exposing (Data, Model, Msg, page)

import Data.Category as Category exposing (Category)
import Data.PostList
import DataSource exposing (DataSource)
import Element as Ui
import Head
import List.Extra as List
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


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
    Category.all
        |> List.map Category.getSlug
        |> List.map (\slug -> { category = slug })
        |> DataSource.succeed



-- DATA


type alias Data =
    Category


data : RouteParams -> DataSource Data
data routeParams =
    Category.singleDataSource routeParams.category



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
    Site.pageMeta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        category =
            static.data

        posts =
            static.sharedData.posts
                |> List.filter (.frontmatter >> .categories >> List.member category)

        titleEls =
            [ Ui.text "Category: "
            , [ Ui.text (Category.getName category) ]
                |> View.Inline.setItalic
            ]

        backToIndexEls =
            [ Ui.text "Back to "
            , [ Ui.text "the index" ]
                |> View.Inline.setLink "/"
            , Ui.text "."
            ]

        subtitle =
            Category.getDescription category
                |> Maybe.map
                    (\desc -> Ui.text (desc ++ " ") :: backToIndexEls)
                |> Maybe.withDefault backToIndexEls
                |> View.Paragraph.view

        content =
            Data.PostList.view posts
    in
    { title = title static
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleEls subtitle
            |> View.PageBody.view
    }
