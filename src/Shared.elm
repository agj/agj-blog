module Shared exposing (Data, Model, Msg(..), PostGist, SharedMsg(..), template)

import Browser.Navigation
import Data.Post as Post exposing (PostFrontmatter)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import Dict
import Html exposing (Html)
import Html.Attributes as Attr
import Maybe.Extra as Maybe
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import QueryParams exposing (QueryParams)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type alias Data =
    List PostGist


type alias PostGist =
    { year : String
    , month : String
    , post : String
    , data : PostFrontmatter
    }


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
    , redirectTargetPostId : Maybe Int
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    let
        maybePostId =
            maybePagePath
                |> Maybe.andThen .pageUrl
                |> Maybe.filter (\{ path } -> Path.toSegments path == [])
                |> Maybe.andThen .query
                |> Maybe.map QueryParams.toDict
                |> Maybe.andThen (Dict.get "p")
                |> Maybe.andThen List.head
                |> Maybe.andThen String.toInt
    in
    ( { showMobileMenu = False
      , redirectTargetPostId = maybePostId
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( { model | showMobileMenu = False }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


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


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { body =
        Html.main_ [ Attr.class "container" ]
            pageView.body
    , title = pageView.title
    }
