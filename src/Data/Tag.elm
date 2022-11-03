module Data.Tag exposing (..)

import DataSource exposing (DataSource)
import DataSource.File
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import Yaml.Decode as Decode exposing (Decoder)


type alias Tag =
    { name : String
    , slug : String
    }


dataSource : DataSource (List Tag)
dataSource =
    DataSource.File.rawFile "data/tags.yaml"
        |> DataSource.map (Decode.fromString (Decode.list decoder))
        |> DataSource.map (Result.withDefault [])


toUrl : Tag -> List Tag -> String
toUrl firstTag moreTags =
    let
        slugs =
            firstTag
                :: moreTags
                |> List.map .slug
                |> String.join ","
    in
    "/tag/?t={slugs}"
        |> String.replace "{slug}" slugs


get : List Tag -> String -> Tag
get tags slug =
    tags
        |> List.find (.slug >> (==) slug)
        |> Maybe.withDefault error


toLink : List (Html.Attribute msg) -> Tag -> Html msg
toLink attrs tag =
    Html.a
        (Attr.href (toUrl tag [])
            :: attrs
        )
        [ Html.text tag.name ]


error : Tag
error =
    { name = "ERROR"
    , slug = "ERROR"
    }



-- INTERNAL


decoder : Decoder Tag
decoder =
    Decode.map2 Tag
        (Decode.field "name" Decode.string)
        (Decode.field "slug" Decode.string)
