module Page.Category exposing (Data, Model, Msg, page)

import Data.Category as Category
import DataSource exposing (DataSource)
import Element as Ui
import Head
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Shared
import Site
import View exposing (View)
import View.Column exposing (Spacing(..))
import View.Inline
import View.PageHeader
import View.Paragraph


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
        [ View.PageHeader.view
            [ Ui.text "Categories" ]
            (Just
                ([ Ui.text "Back to "
                 , [ Ui.text "the index" ]
                    |> View.Inline.setLink "/"
                 , Ui.text "."
                 ]
                    |> View.Paragraph.view
                )
            )
        , Category.viewList
        ]
            |> View.Column.setSpaced MSpacing
    }
