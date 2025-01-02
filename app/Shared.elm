module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Data.Post as Post
import Effect exposing (Effect)
import Element as Ui
import FatalError exposing (FatalError)
import Html exposing (Html)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags maybePagePath =
    ( {}, Effect.none )



-- DATA


type alias Data =
    { posts : List Post.GlobMatchFrontmatter
    }


data : BackendTask FatalError Data
data =
    BackendTask.map Data
        Post.listWithFrontmatterDataSource
        |> BackendTask.allowFatal



-- UPDATE


type Msg
    = SharedMsg SharedMsg


type SharedMsg
    = NoOp


type alias Model =
    {}


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg globalMsg ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none



-- VIEW


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view sharedData page model toMsg pageView =
    { body =
        [ pageView.body
            |> Ui.layout []
        ]
    , title = pageView.title
    }
