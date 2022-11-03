module Data.Category exposing
    ( Category
    , NestedCategory(..)
    , dataSource
    , error
    , get
    , nest
    , toLink
    , toUrl
    , viewList
    )

import DataSource exposing (DataSource)
import DataSource.File
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import Yaml.Decode as Decode exposing (Decoder)


type alias Category =
    { name : String
    , slug : String
    , description : Maybe String
    , parent : Maybe String
    }


type NestedCategory
    = NestedCategory Category (List NestedCategory)


dataSource : DataSource (List Category)
dataSource =
    DataSource.File.rawFile "data/categories.yaml"
        |> DataSource.map (Decode.fromString (Decode.list decoder))
        |> DataSource.map (Result.withDefault [])


toUrl : Category -> String
toUrl { slug } =
    "/category/{slug}"
        |> String.replace "{slug}" slug


get : List Category -> String -> Category
get categories slug =
    categories
        |> List.find (.slug >> (==) slug)
        |> Maybe.withDefault error


nest : List Category -> List NestedCategory
nest categories =
    categories
        |> List.filter (.parent >> Maybe.isNothing)
        |> List.map (nestDelegate categories)


viewList : List Category -> Html msg
viewList categories =
    let
        nestedCategories =
            nest categories
    in
    Html.ul []
        (nestedCategories
            |> List.map viewCategory
        )


toLink : List (Html.Attribute msg) -> Category -> Html msg
toLink attrs category =
    let
        descriptionAttr =
            case category.description of
                Just desc ->
                    Attr.title desc
                        :: attrs

                Nothing ->
                    attrs
    in
    Html.a
        (Attr.href (toUrl category)
            :: descriptionAttr
        )
        [ Html.text category.name ]


error : Category
error =
    { name = "ERROR"
    , slug = "ERROR"
    , description = Nothing
    , parent = Nothing
    }



-- INTERNAL


decoder : Decoder Category
decoder =
    Decode.map4 Category
        (Decode.field "name" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "parent" Decode.string))


nestDelegate : List Category -> Category -> NestedCategory
nestDelegate categories category =
    NestedCategory category
        (categories
            |> List.filter (.parent >> (==) (Just category.slug))
            |> List.map (nestDelegate categories)
        )


viewCategory : NestedCategory -> Html msg
viewCategory (NestedCategory category children) =
    let
        childUl =
            if List.length children > 0 then
                [ Html.ul []
                    (children
                        |> List.map viewCategory
                    )
                ]

            else
                []
    in
    Html.li []
        (toLink [] category
            :: childUl
        )
