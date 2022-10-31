module Page.Index exposing (Data, Model, Msg, page)

import Data.Post as Post exposing (Post, PostFrontmatter)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import Head
import Head.Seo as Seo
import Html exposing (Html)
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
    let
        process : { y : String, m : String, p : String, path : String } -> DataSource PostGist
        process { y, m, p, path } =
            DataSource.File.onlyFrontmatter Post.postFrontmatterDecoder path
                |> DataSource.map
                    (\postData ->
                        { year = y
                        , month = m
                        , post = p
                        , data = postData
                        }
                    )
    in
    Glob.succeed (\y m p path -> { y = y, m = m, p = p, path = path })
        |> Post.routesGlob
        |> Glob.captureFilePath
        |> Glob.toDataSource
        |> DataSource.andThen (List.map process >> DataSource.combine)


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
    , data : PostFrontmatter
    }


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        padNumber : Maybe Int -> String
        padNumber num =
            num
                |> Maybe.withDefault 0
                |> String.fromInt
                |> String.padLeft 2 '0'

        getDateHour : PostGist -> String
        getDateHour gist =
            padNumber gist.data.date
                ++ padNumber gist.data.hour

        sortedGists =
            static.data
                |> List.sortBy (\gist -> gist.year ++ gist.month ++ getDateHour gist)
                |> List.reverse
    in
    { title = "Hi"
    , body =
        sortedGists
            |> List.map viewListedPost
    }


viewListedPost : PostGist -> Html Msg
viewListedPost gist =
    let
        insertGistValuesToString : String -> String
        insertGistValuesToString string =
            string
                |> String.replace "{year}" gist.year
                |> String.replace "{month}" gist.month
                |> String.replace "{post}" gist.post
                |> String.replace "{title}" gist.data.title

        text =
            "{year}/{month} – {title}"
                |> insertGistValuesToString

        url =
            "/{year}/{month}/{post}"
                |> insertGistValuesToString
    in
    Html.li []
        [ Html.a [ Attr.href url ]
            [ Html.text text
            ]
        ]
