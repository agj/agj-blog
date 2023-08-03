module Page.Tag exposing (Data, Model, Msg, page)

import Browser.Navigation
import Custom.List as List
import Data.PageHeader as PageHeader
import Data.PostList
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Element as Ui
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Result.Extra as Result
import Shared
import Site
import Url.Builder exposing (QueryParameter)
import View exposing (View)


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
                |> Ui.layout []

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
            Html.a
                [ Attr.class "removable contrast"
                , Attr.href url
                , Attr.attribute "data-tooltip" "Remove from filter"
                ]
                [ Html.text (Tag.getName tag) ]

        titleChildren =
            if List.length model.queryTags > 0 then
                [ Html.text "Tags: "
                , Html.em []
                    (model.queryTags
                        |> List.map tagToEl
                        |> List.intersperse (Html.text ", ")
                    )
                ]

            else
                [ Html.text "Tags" ]
    in
    { title = title static
    , body =
        [ PageHeader.view titleChildren
            (Just
                (Html.p []
                    [ Html.text "Back to "
                    , Html.a [ Attr.href "/" ] [ Html.text "the index" ]
                    , Html.text "."
                    ]
                )
            )
        , Html.div [ Attr.class "grid" ]
            ((if List.length model.queryTags > 0 then
                [ Html.section [] [ postViews ] ]

              else
                []
             )
                ++ [ Html.section []
                        [ Html.article []
                            [ Html.p []
                                (Tag.listView model.queryTags static.sharedData.posts subTags)
                            ]
                        ]
                   ]
            )
        ]
    }
