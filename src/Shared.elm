module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Navigation
import Data.Category as Category exposing (Category)
import Data.Post as Post
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import Html exposing (Html)
import Html.Attributes as Attr
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
    ( { showMobileMenu = False
      }
    , Cmd.none
    )



-- DATA


type alias Data =
    { posts : List Post.GlobMatchFrontmatter
    , tags : List Tag
    }


data : DataSource Data
data =
    DataSource.map2 Data
        Post.listWithFrontmatterDataSource
        Tag.dataSource



-- UPDATE


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( { model | showMobileMenu = False }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none



-- VIEW


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
