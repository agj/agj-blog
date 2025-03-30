module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Html exposing (Html)
import LanguageTag exposing (emptySubtags)
import LanguageTag.Language
import Pages
import Pages.Manifest as Manifest
import Route exposing (Route)
import Rss
import Site
import Time


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ manifest

    -- Global RSS feed.
    , ApiRoute.succeed
        (rss
            { title = Site.name
            , description = Site.description
            , url = Site.canonicalUrl
            }
            []
            |> BackendTask.succeed
        )
        |> ApiRoute.literal "rss.xml"
        |> ApiRoute.single
        |> ApiRoute.withGlobalHeadTags
            (BackendTask.succeed [ Head.rssLink "/rss.xml" ])

    -- Tag RSS feeds.
    , ApiRoute.succeed
        (\tagName ->
            rss
                { title = Site.name
                , description = Site.description
                , url = Site.canonicalUrl
                }
                []
                |> BackendTask.succeed
        )
        |> ApiRoute.literal "tag"
        |> ApiRoute.slash
        -- Tag name.
        |> ApiRoute.capture
        |> ApiRoute.slash
        |> ApiRoute.literal "rss.xml"
        |> ApiRoute.preRender
            (\route ->
                BackendTask.succeed
                    [ route "javascript" ]
            )
        |> ApiRoute.withGlobalHeadTags
            (BackendTask.succeed [ Head.rssLink "/rss.xml" ])
    ]


{-| `manifest.json` file, describing this website to use as a “progressive web app”.

See: <https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest>

    { title = String
    , description = String
    , url = String
    , lastBuildTime = Time.Posix
    , generator = Maybe String
    , items = List Item
    , siteUrl = String
    }

-}
manifest : ApiRoute ApiRoute.Response
manifest =
    Manifest.init
        { name = Site.name
        , description = Site.description
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }
        |> Manifest.withLang
            (LanguageTag.Language.en
                |> LanguageTag.build emptySubtags
            )
        |> BackendTask.succeed
        |> Manifest.generator Site.canonicalUrl


rss :
    { title : String
    , url : String
    , description : String
    }
    -> List Rss.Item
    -> String
rss config items =
    Rss.generate
        { title = Site.name
        , description = Site.description
        , url = Site.canonicalUrl
        , lastBuildTime = Pages.builtAt
        , generator = Nothing
        , items = items
        , siteUrl = Site.canonicalUrl
        }
