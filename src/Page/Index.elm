module Page.Index exposing (Data, Model, Msg, page)

import Browser.Navigation
import Custom.Element as Ui
import Data.Category as Category exposing (Category, NestedCategory)
import Data.Post as Post
import Data.PostList
import Data.Tag as Tag
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Element as Ui
import Head
import List.Extra as List
import Maybe.Extra as Maybe
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Shared
import Site
import Style
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Heading
import View.PageBody
import View.PageHeader


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

        maybeUrlFragment =
            maybePageUrl
                |> Maybe.andThen .fragment

        findPostGistById id =
            static.sharedData.posts
                |> List.find (\pg -> pg.frontmatter.id == Just id)

        maybePostRedirectCommand =
            maybeRequestedPostId
                |> Maybe.andThen findPostGistById
                |> Maybe.map Post.globMatchFrontmatterToUrl
                |> Maybe.map
                    (\url ->
                        case maybeUrlFragment of
                            Just fragment ->
                                url ++ "#" ++ fragment

                            Nothing ->
                                url
                    )
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
    Site.pageMeta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data {}
    -> View Msg
view maybeUrl sharedModel model static =
    let
        content =
            Ui.row
                [ Ui.width Ui.fill
                , Ui.varSpacing Style.spacing.size5
                ]
                [ Data.PostList.view static.sharedData.posts
                    |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]
                , [ [ Ui.text "Categories" ]
                        |> View.Heading.view 2
                  , Category.viewList
                  , [ Ui.text "Tags" ]
                        |> View.Heading.view 2
                  , Tag.listView [] static.sharedData.posts Tag.all
                  ]
                    |> View.Column.setSpaced MSpacing
                    |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]
                ]
    in
    { title = title static
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitle
                [ Ui.text "agj's blog" ]
            |> View.PageBody.view
    }
