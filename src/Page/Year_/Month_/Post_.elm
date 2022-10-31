module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import Data.Post as Post exposing (Post)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { year : String
    , month : String
    , post : String
    }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    let
        toRouteParamsDataSource : String -> String -> String -> Bool -> DataSource RouteParams
        toRouteParamsDataSource year month slug isHidden =
            if isHidden then
                DataSource.fail "Post is hidden."

            else
                DataSource.succeed
                    { year = year
                    , month = month
                    , post = slug
                    }
    in
    Glob.succeed toRouteParamsDataSource
        |> Glob.match (Glob.literal "data/posts/")
        -- Year
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "/")
        -- Month
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        -- Slug
        |> Glob.capture Glob.wildcard
        -- Hidden post flag
        |> Glob.capture
            (Glob.oneOf
                ( ( "-HIDDEN.md", True )
                , [ ( ".md", False ) ]
                )
            )
        |> Glob.toDataSource
        |> DataSource.resolve


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.File.bodyWithFrontmatter Post.postDecoder
        ("data/posts/{year}/{month}-{post}.md"
            |> String.replace "{year}" routeParams.year
            |> String.replace "{month}" routeParams.month
            |> String.replace "{post}" routeParams.post
        )


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = title static
        }
        |> Seo.website


type alias Data =
    Post Msg


title : StaticPayload Data RouteParams -> String
title static =
    static.data.frontmatter.title


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = title static
    , body =
        Html.node "hgroup"
            []
            [ Html.h1 []
                [ Html.text static.data.frontmatter.title ]
            , Html.p []
                [ Html.text "Categories: "
                , Html.em []
                    [ Html.text (String.join ", " static.data.frontmatter.categories) ]
                , Html.text ". Tags: "
                , Html.em []
                    [ Html.text (String.join ", " static.data.frontmatter.tags) ]
                , Html.text "."
                ]
            ]
            :: static.data.content
    }
