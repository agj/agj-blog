module Page.Index exposing (Data, Model, Msg, page)

import Browser.Navigation
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Post as Post
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Shared
import Site
import View exposing (View)


page : PageWithState {} Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithSharedState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data {} -> ( Model, Cmd Msg )
init maybePageUrl sharedModel static =
    let
        maybeRequestedPostId =
            maybePageUrl
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "p")
                |> Maybe.andThen List.head
                |> Maybe.andThen String.toInt

        findPostGistById id =
            static.sharedData.posts
                |> List.find (\pg -> pg.frontmatter.id == Just id)

        maybePostRedirectCommand =
            maybeRequestedPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map postGistToUrl
                |> Maybe.map Browser.Navigation.load
    in
    ( {}
    , maybePostRedirectCommand
        |> Maybe.withDefault Cmd.none
    )



-- DATA


type alias Data =
    {}


data : DataSource Data
data =
    DataSource.succeed {}



-- UPDATE


type alias Model =
    {}


type alias Msg =
    Never


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data {}
    -> Msg
    -> Model
    -> ( Model, Cmd Msg, Maybe Shared.Msg )
update pageUrl navKey sharedModel static msg model =
    ( {}, Cmd.none, Nothing )



-- SUBSCRIPTIONS


subscriptions : Maybe PageUrl -> {} -> Path -> Model -> Shared.Model -> Sub Msg
subscriptions maybePageUrl _ path model sharedModel =
    Sub.none



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle "Home"


head :
    StaticPayload Data {}
    -> List Head.Tag
head static =
    Site.meta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data {}
    -> View Msg
view maybeUrl sharedModel model static =
    let
        padNumber : Int -> String
        padNumber num =
            num
                |> String.fromInt
                |> String.padLeft 2 '0'

        getDateHour : Post.GlobMatchFrontmatter -> String
        getDateHour gist =
            padNumber gist.frontmatter.date
                ++ padNumber (gist.frontmatter.hour |> Maybe.withDefault 0)

        getTime : Post.GlobMatchFrontmatter -> String
        getTime gist =
            gist.year ++ gist.month ++ getDateHour gist

        gistsByMonth =
            static.sharedData.posts
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
            |> List.map (viewGistMonth static.sharedData.categories)
            |> List.foldl (++) []
    }


viewGistMonth : List Category -> ( String, List Post.GlobMatchFrontmatter ) -> List (Html Msg)
viewGistMonth categories ( month, gists ) =
    [ Html.p []
        [ Html.strong []
            [ Html.text month
            ]
        ]
    , Html.ul []
        (gists
            |> List.map (viewGist categories)
        )
    ]


viewGist : List Category -> Post.GlobMatchFrontmatter -> Html Msg
viewGist categories gist =
    let
        dateText =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')

        postCategories =
            gist.frontmatter.categories
                |> List.map (Category.get categories)
    in
    Html.li []
        [ Html.text dateText
        , Html.a [ Attr.href (postGistToUrl gist) ]
            [ Html.strong []
                [ Html.text gist.frontmatter.title ]
            ]
        , Html.small []
            (Html.text " ("
                :: (List.map viewInlineCategory postCategories
                        |> List.intersperse (Html.text ", ")
                   )
                ++ [ Html.text ")" ]
            )
        ]


viewInlineCategory : Category -> Html Msg
viewInlineCategory category =
    Html.a
        [ Attr.class "secondary"
        , Attr.href (Category.toUrl category)
        ]
        [ Html.text category.name ]



-- UTILITIES


postGistToUrl : Post.GlobMatchFrontmatter -> String
postGistToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" gist.year
        |> String.replace "{month}" gist.month
        |> String.replace "{post}" gist.post
