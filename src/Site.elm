module Site exposing
    ( config
    , pageMeta
    , postMeta
    , windowTitle
    )

import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Tag as Tag exposing (Tag)
import DataSource
import Head
import Head.Seo as Seo
import Pages.Manifest as Manifest
import Pages.Url
import Route
import SiteConfig exposing (SiteConfig)


type alias Data =
    ()


config : SiteConfig Data
config =
    { data = data
    , canonicalUrl = "http://agj.cl/blog"
    , manifest = manifest
    , head = head
    }


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


head : Data -> List Head.Tag
head static =
    []


manifest : Data -> Manifest.Config
manifest static =
    Manifest.init
        { name = name
        , description = description
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }



-- CUSTOMIZED


name : String
name =
    "agj's blog"


description : String
description =
    "Writing about coding weird things, strange thoughts and more random nonsense."


windowTitle : String -> String
windowTitle pageTitle =
    "{pageTitle} [{siteName}]"
        |> String.replace "{pageTitle}" pageTitle
        |> String.replace "{siteName}" name


pageMeta : String -> List Head.Tag
pageMeta title =
    metaBase title
        |> Seo.website


postMeta :
    { title : String
    , year : String
    , month : Int
    , date : Int
    , mainCategory : Maybe Category
    , tags : List Tag
    }
    -> List Head.Tag
postMeta info =
    metaBase info.title
        |> Seo.article
            { publishedTime = Just (Date.formatIso8601Date info.year info.month info.date)
            , modifiedTime = Nothing
            , section =
                info.mainCategory
                    |> Maybe.map Category.getSlug
            , tags =
                info.tags
                    |> List.map Tag.getSlug
            , expirationTime = Nothing
            }


metaBase : String -> Seo.Common
metaBase title =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = name
        , image =
            { url = Pages.Url.external "TODO"
            , alt = name
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = description
        , locale = Nothing
        , title = title
        }
