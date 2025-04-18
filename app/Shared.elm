module Shared exposing
    ( Data
    , MastodonStatusRequest(..)
    , Model
    , Msg(..)
    , template
    )

import BackendTask exposing (BackendTask)
import Data.Mastodon.Status exposing (MastodonStatus)
import Data.Post as Post exposing (PostGist)
import Dict exposing (Dict)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Flags
import Html exposing (Html)
import Http
import Json.Decode
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
init flagsRaw maybePagePath =
    let
        flags =
            case flagsRaw of
                Pages.Flags.BrowserFlags value ->
                    Json.Decode.decodeValue Flags.decoder value
                        |> Result.withDefault Flags.default

                Pages.Flags.PreRenderFlags ->
                    Flags.default
    in
    ( { theme = flags.theme
      , mastodonStatuses = Dict.empty
      }
    , Effect.SetTheme flags.theme
    )



-- DATA


type alias Data =
    { posts : List PostGist
    }


type MastodonStatusRequest
    = MastodonStatusRequesting
    | MastodonStatusObtained MastodonStatus


data : BackendTask FatalError Data
data =
    BackendTask.map Data
        Post.gistsList



-- UPDATE


type Msg
    = SelectedChangeTheme
    | GotMastodonStatus String (Result Http.Error MastodonStatus)


type alias Model =
    { theme : Theme
    , mastodonStatuses : Dict String MastodonStatusRequest
    }


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SelectedChangeTheme ->
            let
                newTheme =
                    Theme.change model.theme
            in
            ( { model | theme = newTheme }
            , Effect.batch
                [ Effect.SaveConfig { theme = newTheme }
                , Effect.SetTheme newTheme
                ]
            )

        GotMastodonStatus statusId (Result.Err _) ->
            ( { model
                | mastodonStatuses =
                    model.mastodonStatuses
                        |> Dict.remove statusId
              }
            , Effect.none
            )

        GotMastodonStatus statusId (Result.Ok mastodonStatus) ->
            ( { model
                | mastodonStatuses =
                    model.mastodonStatuses
                        |> Dict.insert statusId (MastodonStatusObtained mastodonStatus)
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
