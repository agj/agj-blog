module Data.Category exposing
    ( Category
    , NestedCategory(..)
    , all
    , decoder
    , fromSlug
    , getDescription
    , getName
    , getSlug
    , nest
    , toLink
    , toUrl
    , viewList
    )

import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Maybe.Extra as Maybe
import OptimizedDecoder as Decode exposing (Decoder)


type Category
    = Category
        { name : String
        , slug : String
        , parent : Maybe Category
        , description : Maybe String
        }


type NestedCategory
    = NestedCategory Category (List NestedCategory)


categoryInteractive : Category
categoryInteractive =
    Category
        { name = "Interactive"
        , slug = "interactive"
        , description = Just "Video games and other things."
        , parent = Nothing
        }


all : List Category
all =
    [ Category
        { name = "Fiction"
        , slug = "fiction"
        , description = Nothing
        , parent = Nothing
        }
    , categoryInteractive
    , Category
        { name = "Language"
        , slug = "language"
        , description = Nothing
        , parent = Nothing
        }
    , Category
        { name = "Musings"
        , slug = "musings"
        , description = Just "Random personal thoughts."
        , parent = Nothing
        }
    , Category
        { name = "My games"
        , slug = "my-games"
        , description = Nothing
        , parent = Just categoryInteractive
        }
    , Category
        { name = "Opinion"
        , slug = "opinion"
        , description = Nothing
        , parent = Nothing
        }
    , Category
        { name = "Projects"
        , slug = "projects"
        , description = Nothing
        , parent = Nothing
        }
    , Category
        { name = "Sound"
        , slug = "sound"
        , description = Just "Including music."
        , parent = Nothing
        }
    , Category
        { name = "Video"
        , slug = "videos"
        , description = Just "Animated and otherwise."
        , parent = Nothing
        }
    , Category
        { name = "Visual"
        , slug = "graphics"
        , description = Just "Graphic design, illustrations and such."
        , parent = Nothing
        }
    , Category
        { name = "Uncategorized"
        , slug = "uncategorized"
        , description = Nothing
        , parent = Nothing
        }
    ]


getSlug : Category -> String
getSlug (Category { slug }) =
    slug


fromSlug : String -> Result String Category
fromSlug slug =
    all
        |> List.find (\(Category category) -> category.slug == slug)
        |> Result.fromMaybe ("Couldn't find category: " ++ slug)


getName : Category -> String
getName (Category { name }) =
    name


getDescription : Category -> Maybe String
getDescription (Category { description }) =
    description


getParent : Category -> Maybe Category
getParent (Category { parent }) =
    parent


toUrl : Category -> String
toUrl category =
    "/category/{slug}"
        |> String.replace "{slug}" (getSlug category)


nest : List Category -> List NestedCategory
nest categories =
    categories
        |> List.filter (getParent >> Maybe.isNothing)
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
            case getDescription category of
                Just desc ->
                    Attr.title desc
                        :: attrs

                Nothing ->
                    attrs
    in
    Html.a
        ([ Attr.href (toUrl category)
         , Attr.class "category"
         ]
            ++ descriptionAttr
        )
        [ Html.text (getName category) ]


decoder : Decoder Category
decoder =
    Decode.string
        |> Decode.map fromSlug
        |> Decode.andThen Decode.fromResult



-- INTERNAL


nestDelegate : List Category -> Category -> NestedCategory
nestDelegate categories category =
    NestedCategory category
        (categories
            |> List.filter (getParent >> (==) (Just category))
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
