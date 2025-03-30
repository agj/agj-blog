module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import Data.Category exposing (Category)
import Data.Post as Post
import Data.PostList as PostList
import Data.Tag as Tag
import Date
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

    -- Tag RSS feeds.
    , ApiRoute.succeed
        (\tagSlug ->
            Post.listWithFrontmatterDataSource
                |> BackendTask.map
                    (\posts ->
                        posts
                            |> List.filter
                                (\post ->
                                    List.member tagSlug (List.map Tag.getSlug post.frontmatter.tags)
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
                |> BackendTask.allowFatal
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
    -> List Post.GlobMatchFrontmatter
    -> String
rss config posts =
    let
        items : List Rss.Item
        items =
            posts
                |> PostList.sortByTime
                |> List.map postToItem

        postToItem : Post.GlobMatchFrontmatter -> Rss.Item
        postToItem post =
            let
                year =
                    String.toInt post.year
                        |> Maybe.withDefault 1990

                month =
                    String.toInt post.month
                        |> Maybe.withDefault 1
                        |> Date.numberToMonth
            in
            { title = post.frontmatter.title
            , description = ""
            , url = Post.globMatchFrontmatterToUrl post
            , categories = List.map Data.Category.getSlug post.frontmatter.categories
            , author = "agj"
            , pubDate = Rss.Date (Date.fromCalendarDate year month post.frontmatter.date)
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
