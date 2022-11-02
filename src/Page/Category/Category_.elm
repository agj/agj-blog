module Page.Category.Category_ exposing (Data, Model, Msg, page)

import Data.Category as Category exposing (Category)
import DataSource exposing (DataSource)
import DataSource.File
import Head
import Head.Seo as Seo
import OptimizedDecoder as Decode exposing (Decoder)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)
import Yaml.Decode


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { category : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    DataSource.File.rawFile "data/categories.yaml"
        |> DataSource.map (Yaml.Decode.fromString (Yaml.Decode.list Category.decoder))
        |> DataSource.map (Result.withDefault [])
        |> DataSource.map (List.map (\{ slug } -> { category = slug }))


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.succeed ()


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    ()


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    View.placeholder ("Category: " ++ static.routeParams.category)
