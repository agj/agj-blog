module Data.MastodonPost exposing
    ( MastodonPost
    , decoder
    , getCmd
    , idToUrl
    )

import Http
import Json.Decode as Decode exposing (Decoder)


type alias MastodonPost =
    { replies : Int
    }


idToUrl : String -> String
idToUrl mastodonPostId =
    "https://mstdn.social/@agj/{id}"
        |> String.replace "{id}" mastodonPostId


getCmd : (Result Http.Error MastodonPost -> msg) -> String -> Cmd msg
getCmd toMsg postId =
    Http.get
        { url =
            "https://mstdn.social/api/v1/statuses/{postId}"
                |> String.replace "{postId}" postId
        , expect = Http.expectJson toMsg decoder
        }


decoder : Decoder MastodonPost
decoder =
    Decode.map MastodonPost
        (Decode.field "replies_count" Decode.int)
