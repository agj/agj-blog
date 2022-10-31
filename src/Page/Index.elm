module Page.Index exposing (Data, Model, Msg, page)

import Data.Date as Date
import Data.Post as Post exposing (Post, PostFrontmatter)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


type alias Data =
    List PostGist


type alias PostGist =
    { year : String
    , month : String
    , post : String
    , data : PostFrontmatter
    }


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



-- VIEW


title : StaticPayload Data RouteParams -> String
title static =
    Site.windowTitle "Home"


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
        padNumber : Int -> String
        padNumber num =
            num
                |> String.fromInt
                |> String.padLeft 2 '0'

        getDateHour : PostGist -> String
        getDateHour gist =
            padNumber gist.data.date
                ++ padNumber (gist.data.hour |> Maybe.withDefault 0)

        getTime : PostGist -> String
        getTime gist =
            gist.year ++ gist.month ++ getDateHour gist

        gistsByMonth =
            static.data
                |> List.gatherEqualsBy (\gist -> gist.year ++ gist.month)
                |> List.sortBy (Tuple.first >> getTime)
                |> List.map
                    (\( firstGist, rest ) ->
                        ( "{year}, {month}"
                            |> String.replace "{year}" firstGist.year
                            |> String.replace "{month}" (Date.monthNumberToFullName (firstGist.month |> String.toInt |> Maybe.withDefault 0))
                        , firstGist
                            :: rest
                            |> List.sortBy getTime
                            |> List.reverse
                        )
                    )
    in
    { title = title static
    , body =
        gistsByMonth
            |> List.map viewGistMonth
            |> List.foldl (++) []
    }


viewGistMonth : ( String, List PostGist ) -> List (Html Msg)
viewGistMonth ( month, gists ) =
    [ Html.p []
        [ Html.strong []
            [ Html.text month
            ]
        ]
    , Html.ul []
        (gists
            |> List.map viewGist
        )
    ]


viewGist : PostGist -> Html Msg
viewGist gist =
    let
        insertGistValuesToString : String -> String
        insertGistValuesToString string =
            string
                |> String.replace "{year}" gist.year
                |> String.replace "{month}" gist.month
                |> String.replace "{date}" (gist.data.date |> String.fromInt |> String.padLeft 2 '0')
                |> String.replace "{post}" gist.post
                |> String.replace "{title}" gist.data.title
                |> String.replace "{categories}" (gist.data.categories |> String.join ", ")

        dateText =
            "{date} – "
                |> insertGistValuesToString

        categoriesText =
            " ({categories})"
                |> insertGistValuesToString

        url =
            "/{year}/{month}/{post}"
                |> insertGistValuesToString
    in
    Html.li []
        [ Html.text dateText
        , Html.a [ Attr.href url ]
            [ Html.strong []
                [ Html.text gist.data.title ]
            ]
        , Html.small []
            [ Html.text categoriesText ]
        ]
