module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Html exposing (Html)
import LanguageTag exposing (emptySubtags)
import LanguageTag.Language
import Pages.Manifest as Manifest
import Route exposing (Route)
import Site


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ Manifest.generator Site.canonicalUrl (BackendTask.succeed manifest)
    ]


manifest : Manifest.Config
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
