module Route.About exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File
import Doc.ElmUi
import Doc.Markdown
import Element as Ui
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageBody
import View.Paragraph


route : StatelessRoute RouteParams Data ActionData
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
    { markdown : String
    , title : String
    }


type alias ActionData =
    {}


data : BackendTask FatalError Data
data =
    BackendTask.File.bodyWithFrontmatter decoder "data/about.md"
        |> BackendTask.allowFatal


decoder : String -> Decoder Data
decoder content =
    Decode.succeed (Data content)
        |> Decode.required "title" Decode.string



-- VIEW


title : App Data ActionData RouteParams -> String
title app =
    Site.windowTitle app.data.title


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Site.pageMeta (title app)


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    let
        titleEl : List (Html Msg)
        titleEl =
            [ Html.text app.data.title ]

        subtitle : Html Msg
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
            app.data.markdown
                |> Doc.Markdown.parse
                    { audioPlayer = Nothing }
                |> Doc.ElmUi.view Doc.ElmUi.noConfig
    in
    { title = title app
    , body =
        View.PageBody.fromContent content
            |> View.PageBody.withTitleAndSubtitle titleEl subtitle
            |> View.PageBody.view
    }
