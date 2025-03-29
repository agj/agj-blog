module Site exposing
    ( config
    , pageMeta
    , postMeta
    , windowTitle
    )

import BackendTask exposing (BackendTask)
import Data.Category as Category exposing (Category)
import Data.Tag as Tag exposing (Tag)
import Date exposing (Date)
import DateOrDateTime
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Pages.Url
import SiteConfig exposing (SiteConfig)


config : SiteConfig
config =
    { canonicalUrl = "https://blog.agj.cl"
    , head = head
    }


head : BackendTask FatalError (List Head.Tag)
head =
    [ Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
    , Head.sitemapLink "/sitemap.xml"
    ]
        |> BackendTask.succeed



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
    , publishedDate : Date
    , mainCategory : Maybe Category
    , tags : List Tag
    }
    -> List Head.Tag
postMeta info =
    metaBase info.title
        |> Seo.article
            -- { publishedTime = Just (Date.formatIso8601Date info.year info.month info.date)
            { publishedTime = Just (DateOrDateTime.Date info.publishedDate)
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
