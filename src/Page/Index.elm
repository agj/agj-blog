module Page.Index exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.Glob as Glob
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


data : DataSource Data
data =
    Glob.succeed PostGist
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
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    List PostGist


type alias PostGist =
    { year : String
    , month : String
    , post : String
    }


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        sortedGists =
            static.data
                |> List.sortBy (\gist -> gist.year ++ gist.month ++ gist.post)
                |> List.reverse

        insertGistValuesToString : PostGist -> String -> String
        insertGistValuesToString gist string =
            string
                |> String.replace "{year}" gist.year
                |> String.replace "{month}" gist.month
                |> String.replace "{post}" gist.post

        postGistToString : PostGist -> String
        postGistToString gist =
            "{year}/{month} – {post}"
                |> insertGistValuesToString gist

        postGistToUrl : PostGist -> String
        postGistToUrl gist =
            "/{year}/{month}/{post}"
                |> insertGistValuesToString gist

        postGistToLink gist =
            Html.li []
                [ Html.a [ Attr.href (postGistToUrl gist) ]
                    [ Html.text (postGistToString gist)
                    ]
                ]
    in
    { title = "Hi"
    , body =
        sortedGists
            |> List.map postGistToLink
    }
