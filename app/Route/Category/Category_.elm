module Route.Category.Category_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Data.Category as Category exposing (Category)
import Data.PostList
import Element as Ui
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import List.Extra as List
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


type alias Model =
    {}


type alias Msg =
    ()



-- ROUTES


type alias RouteParams =
    { category : String }


pages : BackendTask FatalError (List RouteParams)
pages =
    Category.all
        |> List.map Category.getSlug
        |> List.map (\slug -> { category = slug })
        |> BackendTask.succeed



-- DATA


type alias Data =
    Category


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Category.singleDataSource routeParams.category
        |> BackendTask.mapError FatalError.fromString



-- VIEW


title : App Data ActionData RouteParams -> String
title app =
    "Category: {category}"
        |> String.replace "{category}" app.routeParams.category
        |> Site.windowTitle


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.pageMeta (title app)


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app shared =
    let
        category =
            app.data

        posts =
            app.sharedData.posts
                |> List.filter (.frontmatter >> .categories >> List.member category)

        titleEls : List (Html Msg)
        titleEls =
            [ Ui.text "Category: "
            , [ Ui.text (Category.getName category) ]
                |> View.Inline.setItalic
            ]
                |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])

        backToIndexEls =
            [ Ui.text "Back to "
            , [ Ui.text "the index" ]
                |> View.Inline.setLink Nothing "/"
            , Ui.text "."
            ]

        subtitle : Html Msg
        subtitle =
            Category.getDescription category
                |> Maybe.map
                    (\desc -> Ui.text (desc ++ " ") :: backToIndexEls)
                |> Maybe.withDefault backToIndexEls
                |> View.Paragraph.view
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []

        content =
            Data.PostList.view posts
    in
    { title = title app
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleEls subtitle
            |> View.PageBody.view
    }
