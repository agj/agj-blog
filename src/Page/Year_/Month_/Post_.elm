module Page.Year_.Month_.Post_ exposing (Data, Model, Msg, page)

import Browser.Navigation
import CustomMarkup
import Data.Category as Category
import Data.Date as Date
import Data.PageHeader as PageHeader
import Data.Post as Post exposing (Post)
import Data.Tag as Tag
import DataSource exposing (DataSource)
import Element as Ui
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Shared
import Site
import View exposing (View)
import View.AudioPlayer
import View.CodeBlock
import View.Inline
import View.Paragraph


page : PageWithState RouteParams Data Model Msg
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data RouteParams -> ( Model, Cmd Msg )
init pageUrl sharedModel staticPayload =
    ( { audioPlayerState = View.AudioPlayer.initialState }
    , Cmd.none
    )



-- ROUTES


type alias RouteParams =
    { year : String
    , month : String
    , post : String
    }


routes : DataSource (List RouteParams)
routes =
    Post.listDataSource
        |> DataSource.map
            (List.map
                (\match ->
                    { year = match.year
                    , month = match.month
                    , post = match.post
                    }
                )
            )



-- DATA


type alias Data =
    Post


data : RouteParams -> DataSource Data
data routeParams =
    Post.singleDataSource
        routeParams.year
        routeParams.month
        routeParams.post



-- UPDATE


type alias Model =
    { audioPlayerState : View.AudioPlayer.State }


type Msg
    = AudioPlayerStateUpdated View.AudioPlayer.State


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update pageUrl navigationKey sharedModel staticPayload msg model =
    case msg of
        AudioPlayerStateUpdated state ->
            ( { audioPlayerState = state }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Sub templateMsg
subscriptions pageUrl routeParams path model =
    Sub.none



-- VIEW


title : StaticPayload Data RouteParams -> String
title static =
    Site.windowTitle static.data.frontmatter.title


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Site.postMeta
        { title = title static
        , year = static.routeParams.year
        , month = String.toInt static.routeParams.month |> Maybe.withDefault 0
        , date = static.data.frontmatter.date
        , tags = static.data.frontmatter.tags
        , mainCategory =
            static.data.frontmatter.categories
                |> List.head
        }


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    let
        date =
            Date.formatShortDate
                static.routeParams.year
                (String.toInt static.routeParams.month |> Maybe.withDefault 0)
                static.data.frontmatter.date

        categoryEls =
            static.data.frontmatter.categories
                |> List.map Category.toLink
                |> List.intersperse (Ui.text ", ")

        categoriesTextEls =
            if List.length static.data.frontmatter.categories > 0 then
                [ Ui.text "Categories: "
                , View.Inline.setItalic categoryEls
                , Ui.text ". "
                ]

            else
                [ Ui.text "No categories. " ]

        tagEls =
            static.data.frontmatter.tags
                |> List.map (Tag.toLink [])
                |> List.intersperse (Ui.text ", ")

        tagsTextEls =
            if List.length static.data.frontmatter.tags > 0 then
                [ Ui.text "Tags: "
                , View.Inline.setItalic tagEls
                , Ui.text "."
                ]

            else
                [ Ui.text "No tags." ]

        postInfo =
            ([ Ui.text ("Posted {date}, on " |> String.replace "{date}" date)
             , View.Inline.setLink "/"
                [ Ui.text "agj's blog" ]
             , Ui.text ". "
             ]
                ++ categoriesTextEls
                ++ tagsTextEls
            )
                |> View.Paragraph.view

        contentEl =
            CustomMarkup.toElmUi
                { audioPlayer =
                    Just
                        { audioPlayerState = model.audioPlayerState
                        , onAudioPlayerStateUpdated = AudioPlayerStateUpdated
                        }
                }
                static.data.markdown
    in
    { title = title static
    , body =
        PageHeader.view
            [ Html.text static.data.frontmatter.title ]
            (Just (postInfo |> Ui.layout []))
            :: [ contentEl |> Ui.layoutWith { options = [] } []
               , View.CodeBlock.styles
               ]
    }
