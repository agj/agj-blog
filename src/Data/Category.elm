module Data.Category exposing
    ( Category
    , NestedCategory(..)
    , all
    , allNested
    , decoder
    , fromSlug
    , getDescription
    , getName
    , getSlug
    , toLink
    , toUrl
    , viewList
    )

import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import OptimizedDecoder as Decode exposing (Decoder)


type Category
    = Category
        { name : String
        , slug : String
        , description : Maybe String
        }


type NestedCategory
    = NestedCategory Category (List NestedCategory)


all : List Category
all =
    List.andThen unnest allNested


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


toUrl : Category -> String
toUrl category =
    "/category/{slug}"
        |> String.replace "{slug}" (getSlug category)


viewList : List Category -> Html msg
viewList categories =
    Html.ul []
        (allNested
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


unnest : NestedCategory -> List Category
unnest (NestedCategory category rest) =
    category :: List.andThen unnest rest


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



-- CATEGORIES


allNested : List NestedCategory
allNested =
    [ NestedCategory
        (Category
            { name = "Interactive"
            , slug = "interactive"
            , description = Just "Video games and other things."
            }
        )
        [ NestedCategory
            (Category
                { name = "My games"
                , slug = "my-games"
                , description = Nothing
                }
            )
            []
        ]
    , NestedCategory
        (Category
            { name = "Language"
            , slug = "language"
            , description = Nothing
            }
        )
        []
    , NestedCategory
        (Category
            { name = "Video"
            , slug = "videos"
            , description = Just "Animated and otherwise."
            }
        )
        []
    , NestedCategory
        (Category
            { name = "Visual"
            , slug = "graphics"
            , description = Just "Graphic design, illustrations and such."
            }
        )
        []
    , NestedCategory
        (Category
            { name = "Sound"
            , slug = "sound"
            , description = Just "Including music."
            }
        )
        []
    , NestedCategory
        (Category
            { name = "Musings"
            , slug = "musings"
            , description = Just "Random personal thoughts."
            }
        )
        []
    , NestedCategory
        (Category
            { name = "Projects"
            , slug = "projects"
            , description = Nothing
            }
        )
        []
    ]
