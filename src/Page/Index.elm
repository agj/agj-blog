module Page.Index exposing (Data, Model, Msg, page)

import Browser.Navigation
import Data.Date as Date
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Shared
import Site
import View exposing (View)


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithSharedState
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data RouteParams -> ( Model, Cmd Msg )
init maybePageUrl sharedModel static =
    let
        findPostGistById id =
            static.sharedData
                |> List.find (\pg -> pg.data.id == Just id)

        maybePostRedirectCommand =
            sharedModel.redirectTargetPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map postGistToUrl
                |> Maybe.map Browser.Navigation.load
    in
    ( ()
    , maybePostRedirectCommand
        |> Maybe.withDefault Cmd.none
    )


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload templateData routeParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg, Maybe Shared.Msg )
update pageUrl navKey sharedModel static msg model =
    ( (), Cmd.none, Nothing )


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Shared.Model -> Sub Msg
subscriptions maybePageUrl routeParams path model sharedModel =
    Sub.none


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()



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
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    let
        padNumber : Int -> String
        padNumber num =
            num
                |> String.fromInt
                |> String.padLeft 2 '0'

        getDateHour : Shared.PostGist -> String
        getDateHour gist =
            padNumber gist.data.date
                ++ padNumber (gist.data.hour |> Maybe.withDefault 0)

        getTime : Shared.PostGist -> String
        getTime gist =
            gist.year ++ gist.month ++ getDateHour gist

        gistsByMonth =
            static.sharedData
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


viewGistMonth : ( String, List Shared.PostGist ) -> List (Html Msg)
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


viewGist : Shared.PostGist -> Html Msg
viewGist gist =
    let
        dateText =
            "{date} – "
                |> String.replace "{date}" (gist.data.date |> String.fromInt |> String.padLeft 2 '0')

        categoriesText =
            " ({categories})"
                |> String.replace "{categories}" (gist.data.categories |> String.join ", ")
    in
    Html.li []
        [ Html.text dateText
        , Html.a [ Attr.href (postGistToUrl gist) ]
            [ Html.strong []
                [ Html.text gist.data.title ]
            ]
        , Html.small []
            [ Html.text categoriesText ]
        ]



-- UTILITIES


postGistToUrl : Shared.PostGist -> String
postGistToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" gist.year
        |> String.replace "{month}" gist.month
        |> String.replace "{post}" gist.post
