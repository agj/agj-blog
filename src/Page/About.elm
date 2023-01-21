module Page.About exposing (Data, Model, Msg, page)

import CustomMarkup
import Data.PageHeader as PageHeader
import DataSource exposing (DataSource)
import DataSource.File
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Result.Extra as Result
import Shared
import Site
import View exposing (View)


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
    { title = title static
    , body =
        PageHeader.view
            [ Html.text static.data.title ]
            (Just
                (Html.p []
                    [ Html.text "Back to "
                    , Html.a [ Attr.href "/" ] [ Html.text "the index" ]
                    , Html.text "."
                    ]
                )
            )
            :: CustomMarkup.toHtml static.data.markdown
    }
