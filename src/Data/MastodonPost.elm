module Data.MastodonPost exposing
    ( MastodonPost
    , decoder
    , idToUrl
    )

import Json.Decode as Decode exposing (Decoder)


type alias MastodonPost =
    { replies : Int
    }


idToUrl : String -> String
idToUrl mastodonPostId =
    "https://mstdn.social/@agj/{id}"
        |> String.replace "{id}" mastodonPostId


decoder : Decoder MastodonPost
decoder =
    Decode.map MastodonPost
        (Decode.field "replies_count" Decode.int)
