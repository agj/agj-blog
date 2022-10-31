module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Result.Extra as Result
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
    Glob.succeed RouteParams
        |> Glob.match (Glob.literal "data/posts/")
        -- Year
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "/")
        -- Month
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        -- Slug
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.File.bodyWithFrontmatter postDataDecoder
        ("data/posts/{year}/{month}-{post}.md"
            |> String.replace "{year}" routeParams.year
            |> String.replace "{month}" routeParams.month
            |> String.replace "{post}" routeParams.post
        )


errorToHtml : String -> List (Html Msg)
errorToHtml error =
    [ Html.p []
        [ Html.text "Markdown parsing error:"
        ]
    , Html.pre []
        [ Html.code [] [ Html.text error ]
        ]
    ]


postDataDecoder : String -> Decoder Data
postDataDecoder content =
    let
        parsedContent =
            content
                |> Markdown.Parser.parse
                |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
                |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
                |> Result.mapError errorToHtml
                |> Result.merge
    in
    Decode.succeed (Data parsedContent)
        |> Decode.required "title" Decode.string


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
    { content : List (Html Msg)
    , title : String
    }


title : StaticPayload Data RouteParams -> String
title static =
    static.data.title


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = title static
    , body =
        Html.h1 [] [ Html.text static.data.title ]
            :: static.data.content
    }
