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
    , singleDataSource
    , toLink
    , toUrl
    , viewList
    )

import BackendTask exposing (BackendTask)
import Element as Ui
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra as List
import View.Column exposing (Spacing(..))
import View.Inline
import View.List
import View.Paragraph


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


viewList : Ui.Element msg
viewList =
    allNested
        |> List.map viewCategory
        |> View.List.fromItems
        |> View.List.view


toLink : Category -> Ui.Element msg
toLink category =
    [ Ui.text (getName category) ]
        |> View.Inline.setLink (toUrl category)


decoder : Decoder Category
decoder =
    Decode.string
        |> Decode.map fromSlug
        |> Decode.andThen Decode.fromResult



-- INTERNAL


unnest : NestedCategory -> List Category
unnest (NestedCategory category rest) =
    category :: List.andThen unnest rest


viewCategory : NestedCategory -> List (Ui.Element msg)
viewCategory (NestedCategory category children) =
    let
        childrenList =
            if List.length children > 0 then
                children
                    |> List.map viewCategory
                    |> View.List.fromItems
                    |> View.List.view

            else
                Ui.none

        current =
            [ toLink category ]
                |> View.Paragraph.view
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
