module Shared exposing (Data, Model, Msg(..), template)

import BackendTask exposing (BackendTask)
import Data.Post as Post
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import Theme exposing (Theme)
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
    ( { theme = Theme.Default }
    , Effect.none
    )



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
    = NoOp
    | SelectedChangeTheme


type alias Model =
    { theme : Theme
    }


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        SelectedChangeTheme ->
            ( { model
                | theme =
                    case Debug.log "theme" model.theme of
                        Theme.Default ->
                            Theme.Light

                        Theme.Light ->
                            Theme.Dark

                        Theme.Dark ->
                            Theme.Default
              }
            , Effect.none
            )



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
        [ pageView.body ]
    , title = pageView.title
    }
