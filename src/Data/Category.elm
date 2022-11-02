module Data.Category exposing (Category, dataSource)

import DataSource exposing (DataSource)
import DataSource.File
import Yaml.Decode as Decode exposing (Decoder)


type alias Category =
    { name : String
    , slug : String
    }


dataSource : DataSource (List Category)
dataSource =
    DataSource.File.rawFile "data/categories.yaml"
        |> DataSource.map (Decode.fromString (Decode.list decoder))
        |> DataSource.map (Result.withDefault [])



-- INTERNAL


decoder : Decoder Category
decoder =
    Decode.map2 Category
        (Decode.field "name" Decode.string)
        (Decode.field "slug" Decode.string)
