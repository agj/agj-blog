module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import Data.Category as Category
import Data.Post as Post exposing (PostGist)
import Data.PostList as PostList
import Data.Tag as Tag
import Date
import FatalError exposing (FatalError)
import Html exposing (Html)
import LanguageTag exposing (emptySubtags)
import LanguageTag.Language
import Pages
import Pages.Manifest as Manifest
import Route exposing (Route)
import Rss
import Site


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ manifest

    -- Global RSS feed.
    , ApiRoute.succeed
        (Post.gistsList
            |> BackendTask.map
                (rss
                    { title = Site.name
                    , description = Site.description
                    , url = Site.canonicalUrl
                    }
                )
        )
        |> ApiRoute.literal "rss.xml"
        |> ApiRoute.single

    -- Categories RSS feeds.
    , ApiRoute.succeed
        (\categorySlug ->
            Post.gistsList
                |> BackendTask.map
                    (\posts ->
                        posts
                            |> List.filter
                                (\post ->
                                    List.member categorySlug (List.map Category.getSlug post.categories)
                                        && not post.isHidden
                                )
                            |> rss
                                { title = Site.name
                                , description = Site.description
                                , url =
                                    "{root}/category/{categorySlug}"
                                        |> String.replace "{root}" Site.canonicalUrl
                                        |> String.replace "{categorySlug}" categorySlug
                                }
                    )
        )
        |> ApiRoute.literal "category"
        |> ApiRoute.slash
        -- Category slug.
        |> ApiRoute.capture
        |> ApiRoute.slash
        |> ApiRoute.literal "rss.xml"
        |> ApiRoute.preRender
            (\route ->
                Category.all
                    |> List.map (\category -> route (Category.getSlug category))
                    |> BackendTask.succeed
            )

    -- Tag RSS feeds.
    , ApiRoute.succeed
        (\tagSlug ->
            Post.gistsList
                |> BackendTask.map
                    (\posts ->
                        posts
                            |> List.filter
                                (\post ->
                                    List.member tagSlug (List.map Tag.getSlug post.tags)
                                        && not post.isHidden
                                )
                            |> rss
                                { title = Site.name
                                , description = Site.description
                                , url =
                                    "{root}/tag?t={tagSlug}"
                                        |> String.replace "{root}" Site.canonicalUrl
                                        |> String.replace "{tagSlug}" tagSlug
                                }
                    )
        )
        |> ApiRoute.literal "tag"
        |> ApiRoute.slash
        -- Tag slug.
        |> ApiRoute.capture
        |> ApiRoute.slash
        |> ApiRoute.literal "rss.xml"
        |> ApiRoute.preRender
            (\route ->
                Tag.all
                    |> List.map (\tag -> route (Tag.getSlug tag))
                    |> BackendTask.succeed
            )
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
    -> List PostGist
    -> String
rss config posts =
    let
        items : List Rss.Item
        items =
            posts
                |> PostList.sortByTime
                |> List.map postToItem

        postToItem : PostGist -> Rss.Item
        postToItem post =
            { title = post.title
            , description = ""
            , url = Post.gistToUrl post
            , categories = List.map Category.getSlug post.categories
            , author = "agj"
            , pubDate = Rss.DateTime post.dateTime
            , content = Nothing
            , contentEncoded = Nothing
            , enclosure = Nothing
            }
    in
    Rss.generate
        { title = config.title
        , description = config.description
        , url = config.url
        , lastBuildTime = Pages.builtAt
        , generator = Nothing
        , items = items
        , siteUrl = Site.canonicalUrl
        }
