module Page.Category exposing (Data, Model, Msg, page)

import Data.Category as Category
import Data.PageHeader as PageHeader
import DataSource exposing (DataSource)
import Element as Ui
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)


page : Page {} Data
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



-- DATA


type alias Data =
    ()


data : DataSource Data
data =
    DataSource.succeed ()



-- VIEW


title : StaticPayload Data {} -> String
title static =
    Site.windowTitle "Categories"


head :
    StaticPayload Data {}
    -> List Head.Tag
head static =
    Site.pageMeta (title static)


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data {}
    -> View Msg
view maybeUrl sharedModel static =
    { title = title static
    , body =
        [ PageHeader.view
            [ Html.text "Categories" ]
            (Just
                (Html.p []
                    [ Html.text "Back to "
                    , Html.a [ Attr.href "/" ] [ Html.text "the index" ]
                    , Html.text "."
                    ]
                )
            )
        , Category.viewList
            |> Ui.layout []
        ]
    }
