module Data.Mastodon.Status exposing
    ( MastodonStatus
    , decoder
    , getCmd
    , idToUrl
    )

import Http
import Json.Decode as Decode exposing (Decoder)


type alias MastodonStatus =
    { replies : Int
    }


idToUrl : String -> String
idToUrl mastodonPostId =
    "https://mstdn.social/@agj/{id}"
        |> String.replace "{id}" mastodonPostId


getCmd : (Result Http.Error MastodonStatus -> msg) -> String -> Cmd msg
getCmd toMsg postId =
    Http.get
        { url =
            "https://mstdn.social/api/v1/statuses/{postId}"
                |> String.replace "{postId}" postId
        , expect = Http.expectJson toMsg decoder
        }


decoder : Decoder MastodonStatus
decoder =
    Decode.map MastodonStatus
        (Decode.field "replies_count" Decode.int)
