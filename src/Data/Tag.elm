module Data.Tag exposing
    ( Tag
    , dataSource
    , error
    , get
    , listView
    , toLink
    , toUrl
    )

import Data.Post as Post
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
        |> String.replace "{slugs}" slugs


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


listView : List Post.GlobMatchFrontmatter -> List Tag -> List (Html msg)
listView posts tags =
    let
        tagsCount =
            tags
                |> List.map
                    (\tag ->
                        ( tag
                        , posts
                            |> List.filter
                                (\post ->
                                    List.any ((==) tag.slug) post.frontmatter.tags
                                )
                            |> List.length
                        )
                    )

        maxCount =
            tagsCount
                |> List.map Tuple.second
                |> List.maximum
                |> Maybe.withDefault 0

        minCount =
            tagsCount
                |> List.map Tuple.second
                |> List.minimum
                |> Maybe.withDefault 0

        tagElAttrs count =
            let
                opacity =
                    (toFloat (count - minCount) / toFloat (maxCount - minCount) * 0.7)
                        + 0.3
            in
            [ Attr.style "white-space" "nowrap"
            , Attr.style "opacity" (String.fromFloat opacity)
            , Attr.title ("Posts: " ++ String.fromInt count)
            ]
    in
    tagsCount
        |> List.map (\( tag, count ) -> toLink (tagElAttrs count) tag)
        |> List.intersperse (Html.text ", ")


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
