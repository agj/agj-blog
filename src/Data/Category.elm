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
    = Fiction
    | Interactive
    | Language
    | Musings
    | MyGames
    | Opinion
    | Projects
    | Sound
    | Video
    | Visual
    | Uncategorized


type NestedCategory
    = NestedCategory Category (List NestedCategory)


all : List Category
all =
    [ Fiction
    , Interactive
    , Language
    , Musings
    , MyGames
    , Opinion
    , Projects
    , Sound
    , Video
    , Visual
    , Uncategorized
    ]


getSlug : Category -> String
getSlug category =
    case category of
        Fiction ->
            "fiction"

        Interactive ->
            "interactive"

        Language ->
            "language"

        Musings ->
            "musings"

        MyGames ->
            "my-games"

        Opinion ->
            "opinion"

        Projects ->
            "projects"

        Sound ->
            "sound"

        Video ->
            "videos"

        Visual ->
            "graphics"

        Uncategorized ->
            "uncategorized"


fromSlug : String -> Result String Category
fromSlug slug =
    case slug of
        "fiction" ->
            Ok Fiction

        "interactive" ->
            Ok Interactive

        "language" ->
            Ok Language

        "musings" ->
            Ok Musings

        "my-games" ->
            Ok MyGames

        "opinion" ->
            Ok Opinion

        "projects" ->
            Ok Projects

        "sound" ->
            Ok Sound

        "videos" ->
            Ok Video

        "graphics" ->
            Ok Visual

        "uncategorized" ->
            Ok Uncategorized

        _ ->
            Err ("Category not found: " ++ slug)


getName : Category -> String
getName category =
    case category of
        Fiction ->
            "Fiction"

        Interactive ->
            "Interactive"

        Language ->
            "Language"

        Musings ->
            "Musings"

        MyGames ->
            "My games"

        Opinion ->
            "Opinion"

        Projects ->
            "Projects"

        Sound ->
            "Sound"

        Video ->
            "Video"

        Visual ->
            "Visual"

        Uncategorized ->
            "Uncategorized"


getDescription : Category -> Maybe String
getDescription category =
    case category of
        Interactive ->
            Just "Video games and other things."

        Musings ->
            Just "Random personal thoughts."

        Sound ->
            Just "Including music."

        Video ->
            Just "Animated and otherwise."

        Visual ->
            Just "Graphic design, illustrations and such."

        _ ->
            Nothing


getParent : Category -> Maybe Category
getParent category =
    case category of
        MyGames ->
            Just Interactive

        _ ->
            Nothing


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
