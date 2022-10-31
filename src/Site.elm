module Site exposing (config, meta, windowTitle)

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
    , canonicalUrl = "https://elm-pages.com"
    , manifest = manifest
    , head = head
    }


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


head : Data -> List Head.Tag
head static =
    [ Head.sitemapLink "/sitemap.xml"
    ]


manifest : Data -> Manifest.Config
manifest static =
    Manifest.init
        { name = "Site Name"
        , description = "Description"
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }



-- CUSTOMIZED


windowTitle : String -> String
windowTitle pageTitle =
    "{pageTitle} [agj's blog]"
        |> String.replace "{pageTitle}" pageTitle


meta : String -> List Head.Tag
meta title =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "agj's blog"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "agj's blog"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Writing about coding weird things, strange thoughts and more random nonsense."
        , locale = Nothing
        , title = title
        }
        |> Seo.website
