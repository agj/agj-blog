module Data.Category exposing (..)

import Yaml.Decode as Decode exposing (Decoder)


type alias Category =
    { name : String
    , slug : String
    }


decoder : Decoder Category
decoder =
    Decode.map2 Category
        (Decode.field "name" Decode.string)
        (Decode.field "slug" Decode.string)
