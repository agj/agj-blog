module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Markdown.Parser
import Markdown.Renderer
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
    { year : String, month : String, post : String }


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
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.File.rawFile
        ("data/posts/{year}/{month}/{post}.md"
            |> String.replace "{year}" routeParams.year
            |> String.replace "{month}" routeParams.month
            |> String.replace "{post}" routeParams.post
        )
        |> DataSource.map Data


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
    { content : String
    }


title : StaticPayload Data RouteParams -> String
title static =
    static.routeParams.post


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = title static
    , body =
        [ Html.text
            (static.routeParams.year
                ++ " / "
                ++ static.routeParams.month
                ++ " / "
                ++ static.routeParams.post
            )
        , Html.main_ [ Attr.class "container" ]
            (static.data.content
                |> Markdown.Parser.parse
                |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
                |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
                |> Result.withDefault []
            )
        ]
    }
