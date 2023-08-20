module Page.About exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File
import Doc.Markdown
import Doc.Render
import Element as Ui
import Head
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageHeader
import View.Paragraph


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}



-- DATA


type alias Data =
    { markdown : String
    , title : String
    }


data : DataSource Data
data =
    DataSource.File.bodyWithFrontmatter decoder "data/about.md"


decoder : String -> Decoder Data
decoder content =
    Decode.succeed (Data content)
        |> Decode.required "title" Decode.string



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle static.data.title


head :
    StaticPayload Data {}
    -> List Head.Tag
head static =
    Site.pageMeta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    let
        content =
            static.data.markdown
                |> Doc.Markdown.parse
                    { audioPlayer = Nothing }
                |> Doc.Render.toElmUi Nothing
    in
    { title = title static
    , body =
        View.PageHeader.view
            [ Ui.text static.data.title ]
            (Just
                ([ Ui.text "Back to "
                 , [ Ui.text "the index" ]
                    |> View.Inline.setLink "/"
                 , Ui.text "."
                 ]
                    |> View.Paragraph.view
                )
            )
            :: [ content ]
            |> View.Column.setSpaced MSpacing
    }
