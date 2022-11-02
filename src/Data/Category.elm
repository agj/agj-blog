module Data.Category exposing (Category, dataSource, error, toUrl)

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


toUrl : Category -> String
toUrl { slug } =
    "/category/{slug}"
        |> String.replace "{slug}" slug


error : Category
error =
    { name = "ERROR"
    , slug = "ERROR"
    }



-- INTERNAL


decoder : Decoder Category
decoder =
    Decode.map2 Category
        (Decode.field "name" Decode.string)
        (Decode.field "slug" Decode.string)
