module Route.Category exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Data.Category as Category
import Element as Ui
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}



-- DATA


type alias Data =
    {}


type alias ActionData =
    {}


data : BackendTask FatalError Data
data =
    BackendTask.succeed {}



-- VIEW


title : String
title =
    Site.windowTitle "Categories"


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Site.pageMeta title


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    let
        titleEls : List (Html msg)
        titleEls =
            [ Html.text "Categories" ]

        subtitle : Html msg
        subtitle =
            [ Ui.text "Back to "
            , [ Ui.text "the index" ]
                |> View.Inline.setLink Nothing "/"
            , Ui.text "."
            ]
                |> View.Paragraph.view
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []

        content : Html Msg
        content =
            Category.viewList
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []
    in
    { title = title
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleEls subtitle
            |> View.PageBody.view
    }
