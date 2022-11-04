module Data.Tag exposing
    ( Tag
    , baseUrl
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


baseUrl : String
baseUrl =
    "/tag/"


toUrl : Tag -> List Tag -> String
toUrl firstTag moreTags =
    let
        slugs =
            firstTag
                :: moreTags
                |> List.map .slug
                |> List.sort
                |> String.join "&t="
    in
    "{baseUrl}?t={slugs}"
        |> String.replace "{baseUrl}" baseUrl
        |> String.replace "{slugs}" slugs


get : List Tag -> String -> Tag
get tags slug =
    tags
        |> List.find (.slug >> (==) slug)
        |> Maybe.withDefault error


toLink : List Tag -> List (Html.Attribute msg) -> Tag -> Html msg
toLink tagsToAddTo attrs tag =
    let
        aEl =
            Html.a
                ([ Attr.href (toUrl tag [])
                 , Attr.class "tag"
                 ]
                    ++ attrs
                )
                [ Html.text tag.name ]
    in
    case tagsToAddTo of
        moreTag :: moreTags ->
            Html.span [ Attr.class "tag" ]
                [ aEl
                , Html.text " "
                , Html.a
                    [ Attr.href (toUrl tag (moreTag :: moreTags))
                    , Attr.attribute "role" "button"
                    , Attr.attribute "data-tooltip" "Add to filter"
                    ]
                    [ Html.text "+" ]
                ]

        [] ->
            aEl


listView : List Tag -> List Post.GlobMatchFrontmatter -> List Tag -> List (Html msg)
listView tagsInView posts tags =
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
            [ Attr.style "opacity" (String.fromFloat opacity) ]
    in
    tagsCount
        |> List.map (\( tag, count ) -> toLink tagsInView (tagElAttrs count) tag)
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
