module Data.Category exposing
    ( Category
    , NestedCategory(..)
    , all
    , decoder
    , getDescription
    , getName
    , getSlug
    , singleDataSource
    , toLink
    , toUrl
    , viewList
    )

import BackendTask exposing (BackendTask)
import Custom.Html
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra as List
import View.Inline
import View.List


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


singleDataSource : String -> BackendTask String Category
singleDataSource slug =
    fromSlug slug
        |> BackendTask.fromResult


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


viewList : Html msg
viewList =
    allNested
        |> List.map viewCategory
        |> View.List.fromItems
        |> View.List.view


toLink : Category -> Html msg
toLink category =
    [ Html.text (getName category) ]
        |> View.Inline.setLink Nothing (toUrl category)


decoder : Decoder Category
decoder =
    Decode.string
        |> Decode.map fromSlug
        |> Decode.andThen Decode.fromResult



-- INTERNAL


unnest : NestedCategory -> List Category
unnest (NestedCategory category rest) =
    category :: List.andThen unnest rest


viewCategory : NestedCategory -> List (Html msg)
viewCategory (NestedCategory category children) =
    let
        childrenList : Html msg
        childrenList =
            if List.length children > 0 then
                children
                    |> List.map viewCategory
                    |> View.List.fromItems
                    |> View.List.view

            else
                Custom.Html.none

        current : Html msg
        current =
            Html.div []
                [ toLink category ]
    in
    [ current, childrenList ]



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
