module Flags exposing (..)

import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Theme exposing (Theme)


type alias Flags =
    { theme : Theme }


default : Flags
default =
    { theme = Theme.default }


decoder : Decoder Flags
decoder =
    Json.Decode.map Flags
        (Json.Decode.field "theme" Theme.decoder)


encode : Flags -> Value
encode flags =
    Json.Encode.object [ ( "theme", Theme.encode flags.theme ) ]
