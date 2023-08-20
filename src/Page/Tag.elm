module Page.Tag exposing (Data, Model, Msg, page)

import Browser.Navigation
import Custom.Element as Ui
import Custom.List as List
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Element as Ui
import Head
import List.Extra as List
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Result.Extra as Result
import Shared
import Site
import Style
import Url.Builder exposing (QueryParameter)
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


page : PageWithState {} Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data {} -> ( Model, Cmd Msg )
init maybePageUrl sharedModel static =
    let
        queryTags =
            maybePageUrl
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "t")
                |> Maybe.withDefault []
                |> List.map Tag.fromSlug
                |> List.filter Result.isOk
                |> Result.combine
                |> Result.withDefault []
    in
    ( { queryTags = queryTags }, Cmd.none )



-- DATA


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()



-- UPDATE


type alias Model =
    { queryTags : List Tag
    }


type alias Msg =
    Never


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data {}
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
update pageUrl navKey sharedModel static msg model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Maybe PageUrl -> {} -> Path -> Model -> Sub Msg
subscriptions maybePageUrl _ path model =
    Sub.none



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle "Tags"


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
        posts =
            static.sharedData.posts
                |> List.filter
                    (\post ->
                        model.queryTags
                            |> List.all (List.memberOf post.frontmatter.tags)
                    )

        postViews =
            Data.PostList.view posts

        subTags =
            posts
                |> List.andThen (.frontmatter >> .tags)
                |> List.unique
                |> List.filter (List.memberOf model.queryTags >> not)

        tagToEl tag =
            let
                url =
                    case List.remove tag model.queryTags of
                        otherTag1 :: otherTagsRest ->
                            Tag.toUrl otherTag1 otherTagsRest

                        [] ->
                            Tag.baseUrl
            in
            [ Ui.text (Tag.getName tag) ]
                |> View.Inline.setLink url

        titleChildren =
            if List.length model.queryTags > 0 then
                [ Ui.text "Tags: "
                , (model.queryTags
                    |> List.map tagToEl
                    |> List.intersperse (Ui.text ", ")
                  )
                    |> View.Inline.setItalic
                ]

            else
                [ Ui.text "Tags" ]

        subtitle =
            [ Ui.text "Back to "
            , [ Ui.text "the index" ]
                |> View.Inline.setLink "/"
            , Ui.text "."
            ]
                |> View.Paragraph.view

        postColumn =
            if List.length model.queryTags > 0 then
                postViews
                    |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]

            else
                Ui.none

        tagsColumn =
            Tag.listView model.queryTags static.sharedData.posts subTags
                |> Ui.el [ Ui.alignTop, Ui.width (Ui.fillPortion 1) ]

        content =
            [ postColumn
            , tagsColumn
            ]
                |> Ui.row
                    [ Ui.width Ui.fill
                    , Ui.varSpacing Style.spacing.size5
                    ]
    in
    { title = title static
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleChildren subtitle
            |> View.PageBody.view
    }
