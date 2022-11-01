module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Navigation
import DataSource
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
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
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
                |> Maybe.andThen
                    (\value ->
                        case value of
                            [ id ] ->
                                String.toInt id

                            _ ->
                                Nothing
                    )
    in
    ( { showMobileMenu = False }
    , case maybePostId of
        Just id ->
            Browser.Navigation.load ("https://elm-lang.org?p=" ++ String.fromInt id)

        Nothing ->
            Cmd.none
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


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


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
