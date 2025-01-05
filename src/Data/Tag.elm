module Data.Tag exposing
    ( Tag
    , all
    , baseUrl
    , decoder
    , fromSlug
    , getName
    , getSlug
    , listView
    , slugsToUrl
    , toLink
    , toUrl
    )

import Element as Ui
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra as List
import Maybe.Extra as Maybe
import View.Inline
import View.Paragraph


type Tag
    = Tag
        { name : String
        , slug : String
        }


getSlug : Tag -> String
getSlug (Tag { slug }) =
    slug


fromSlug : String -> Result String Tag
fromSlug slug =
    all
        |> List.find (\(Tag tag) -> tag.slug == slug)
        |> Result.fromMaybe ("Couldn't find tag: " ++ slug)


getName : Tag -> String
getName (Tag { name }) =
    name


baseUrl : String
baseUrl =
    "/tag/"


toUrl : Tag -> List Tag -> String
toUrl firstTag moreTags =
    slugsToUrl
        (getSlug firstTag)
        (List.map getSlug moreTags)


slugsToUrl : String -> List String -> String
slugsToUrl firstSlug moreSlugs =
    let
        slugs =
            firstSlug
                :: moreSlugs
                |> List.sort
                |> String.join "&t="
    in
    "{baseUrl}?t={slugs}"
        |> String.replace "{baseUrl}" baseUrl
        |> String.replace "{slugs}" slugs


toLink : Maybe (String -> msg) -> List Tag -> Tag -> Ui.Element msg
toLink onClick tagsToAddTo tag =
    let
        singleLink =
            [ Ui.text (getName tag) ]
                |> View.Inline.setLink onClick (toUrl tag [])
    in
    case tagsToAddTo of
        _ :: _ ->
            let
                addLink =
                    [ Ui.text "+" ]
                        |> View.Inline.setLink onClick (toUrl tag tagsToAddTo)
            in
            [ singleLink
            , Ui.text "["
            , addLink
            , Ui.text "]"
            ]
                |> Ui.paragraph []

        [] ->
            singleLink


listView :
    Maybe (String -> msg)
    -> List Tag
    -> List { a | frontmatter : { b | tags : List Tag } }
    -> List Tag
    -> Ui.Element msg
listView onClick selectedTags posts relatedTags =
    let
        tagsCount =
            relatedTags
                |> List.map
                    (\tag ->
                        ( tag
                        , posts
                            |> List.filter
                                (\post ->
                                    List.any ((==) tag) post.frontmatter.tags
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
    in
    tagsCount
        |> List.map (\( tag, count ) -> toLink onClick selectedTags tag)
        |> List.intersperse (Ui.text ", ")
        |> View.Paragraph.view


decoder : Decoder Tag
decoder =
    Decode.string
        |> Decode.map fromSlug
        |> Decode.andThen Decode.fromResult



-- TAGS


all : List Tag
all =
    [ Tag
        { name = "(Sin asunto)"
        , slug = "sin-asunto"
        }
    , Tag
        { name = "Adobe AIR"
        , slug = "adobe-air"
        }
    , Tag
        { name = "album"
        , slug = "album"
        }
    , Tag
        { name = "animation"
        , slug = "animation"
        }
    , Tag
        { name = "anime"
        , slug = "anime"
        }
    , Tag
        { name = "Anything"
        , slug = "anything"
        }
    , Tag
        { name = "archive"
        , slug = "archive"
        }
    , Tag
        { name = "Asymmetric feedback"
        , slug = "asymmetric-feedback"
        }
    , Tag
        { name = "audio games"
        , slug = "audio-games"
        }
    , Tag
        { name = "blog"
        , slug = "blog"
        }
    , Tag
        { name = "book"
        , slug = "book"
        }
    , Tag
        { name = "Buranko"
        , slug = "buranko"
        }
    , Tag
        { name = "campodecolor"
        , slug = "campodecolor"
        }
    , Tag
        { name = "Cave Trip"
        , slug = "cave-trip"
        }
    , Tag
        { name = "CCPLM"
        , slug = "ccplm"
        }
    , Tag
        { name = "Chile"
        , slug = "chile"
        }
    , Tag
        { name = "cinema"
        , slug = "cinema"
        }
    , Tag
        { name = "Climbrunner"
        , slug = "climbrunner"
        }
    , Tag
        { name = "collaboration"
        , slug = "collaboration"
        }
    , Tag
        { name = "Come to think of language"
        , slug = "come-to-think-of-language"
        }
    , Tag
        { name = "comic"
        , slug = "comic"
        }
    , Tag
        { name = "competition"
        , slug = "competition"
        }
    , Tag
        { name = "composition"
        , slug = "composition"
        }
    , Tag
        { name = "conlang"
        , slug = "conlang"
        }
    , Tag
        { name = "Construct"
        , slug = "construct"
        }
    , Tag
        { name = "dot-into"
        , slug = "dot-into"
        }
    , Tag
        { name = "dream"
        , slug = "dream"
        }
    , Tag
        { name = "Elm"
        , slug = "elm"
        }
    , Tag
        { name = "Entretenimientos Diana"
        , slug = "entretenimientos-diana"
        }
    , Tag
        { name = "español"
        , slug = "espanol"
        }
    , Tag
        { name = "event"
        , slug = "event"
        }
    , Tag
        { name = "exhibition"
        , slug = "exhibition"
        }
    , Tag
        { name = "family"
        , slug = "family"
        }
    , Tag
        { name = "final year's project"
        , slug = "final-years-project"
        }
    , Tag
        { name = "Flash"
        , slug = "flash"
        }
    , Tag
        { name = "Flixel"
        , slug = "flixel"
        }
    , Tag
        { name = "Flower pattern"
        , slug = "flower-pattern"
        }
    , Tag
        { name = "for children"
        , slug = "for-children"
        }
    , Tag
        { name = "forum"
        , slug = "forum"
        }
    , Tag
        { name = "Frogs Drink Faces"
        , slug = "frogs-drink-faces"
        }
    , Tag
        { name = "front page design"
        , slug = "front-page-design"
        }
    , Tag
        { name = "function-promisifier"
        , slug = "function-promisifier"
        }
    , Tag
        { name = "Game Boy"
        , slug = "game-boy"
        }
    , Tag
        { name = "Game Boy Camera"
        , slug = "game-boy-camera"
        }
    , Tag
        { name = "game engine"
        , slug = "game-engine"
        }
    , Tag
        { name = "games aggregate"
        , slug = "games-aggregate"
        }
    , Tag
        { name = "Gently"
        , slug = "gently"
        }
    , Tag
        { name = "graphic design"
        , slug = "graphic-design"
        }
    , Tag
        { name = "GregWS"
        , slug = "gregws"
        }
    , Tag
        { name = "Halloween"
        , slug = "halloween"
        }
    , Tag
        { name = "Heart"
        , slug = "heart"
        }
    , Tag
        { name = "IGF"
        , slug = "igf"
        }
    , Tag
        { name = "illustration"
        , slug = "illustration"
        }
    , Tag
        { name = "industry"
        , slug = "industry"
        }
    , Tag
        { name = "Inform 7"
        , slug = "inform-7"
        }
    , Tag
        { name = "Interactive"
        , slug = "interactive"
        }
    , Tag
        { name = "interactive fiction"
        , slug = "interactive-fiction"
        }
    , Tag
        { name = "Intervalo lúcido del individuo inconsciente"
        , slug = "intervalo-lucido-del-individuo-inconsciente"
        }
    , Tag
        { name = "January"
        , slug = "january"
        }
    , Tag
        { name = "Japan"
        , slug = "japan"
        }
    , Tag
        { name = "japanese"
        , slug = "japanese"
        }
    , Tag
        { name = "Japoñol"
        , slug = "japonol"
        }
    , Tag
        { name = "javascript"
        , slug = "javascript"
        }
    , Tag
        { name = "Jugosa Cocina para Niños"
        , slug = "jugosa-cocina-para-ninos"
        }
    , Tag
        { name = "Knytt of the Month"
        , slug = "knytt-of-the-month"
        }
    , Tag
        { name = "Knytt Stories"
        , slug = "knytt-stories"
        }
    , Tag
        { name = "KOTM"
        , slug = "kotm"
        }
    , Tag
        { name = "language"
        , slug = "language"
        }
    , Tag
        { name = "library"
        , slug = "library"
        }
    , Tag
        { name = "literature"
        , slug = "literature"
        }
    , Tag
        { name = "lofi"
        , slug = "lofi"
        }
    , Tag
        { name = "Ludum Dare"
        , slug = "ludum-dare"
        }
    , Tag
        { name = "magazine"
        , slug = "magazine"
        }
    , Tag
        { name = "Metaclase de Kanji"
        , slug = "metaclase-de-kanji"
        }
    , Tag
        { name = "micro-story"
        , slug = "micro-story"
        }
    , Tag
        { name = "motion graphics"
        , slug = "motion-graphics"
        }
    , Tag
        { name = "Muévete"
        , slug = "muevete"
        }
    , Tag
        { name = "museography"
        , slug = "museography"
        }
    , Tag
        { name = "music video"
        , slug = "music-video"
        }
    , Tag
        { name = "Nendo project"
        , slug = "nendo-project"
        }
    , Tag
        { name = "NitroTracker"
        , slug = "nitrotracker"
        }
    , Tag
        { name = "openFrameworks"
        , slug = "openframeworks"
        }
    , Tag
        { name = "pen-and-paper game"
        , slug = "pen-and-paper-game"
        }
    , Tag
        { name = "perception"
        , slug = "perception"
        }
    , Tag
        { name = "photomotion"
        , slug = "photomotion"
        }
    , Tag
        { name = "PHP"
        , slug = "php"
        }
    , Tag
        { name = "Pirate Kart"
        , slug = "pirate-kart"
        }
    , Tag
        { name = "pixel art"
        , slug = "pixel-art"
        }
    , Tag
        { name = "portfolio"
        , slug = "portfolio"
        }
    , Tag
        { name = "post-mortem"
        , slug = "post-mortem"
        }
    , Tag
        { name = "Prosopamnesia"
        , slug = "prosopamnesia"
        }
    , Tag
        { name = "Racket"
        , slug = "racket"
        }
    , Tag
        { name = "release"
        , slug = "release"
        }
    , Tag
        { name = "Runnerby"
        , slug = "runnerby"
        }
    , Tag
        { name = "Santiago"
        , slug = "santiago"
        }
    , Tag
        { name = "Santiago en 100 palabras"
        , slug = "santiago-en-100-palabras"
        }
    , Tag
        { name = "Sheets"
        , slug = "sheets"
        }
    , Tag
        { name = "short film"
        , slug = "short-film"
        }
    , Tag
        { name = "Sound"
        , slug = "sound"
        }
    , Tag
        { name = "sound design"
        , slug = "sound-design"
        }
    , Tag
        { name = "Spwords"
        , slug = "spwords"
        }
    , Tag
        { name = "story"
        , slug = "story"
        }
    , Tag
        { name = "storyboard"
        , slug = "storyboard"
        }
    , Tag
        { name = "Super Friendship Club"
        , slug = "super-friendship-club"
        }
    , Tag
        { name = "surrealism"
        , slug = "surrealism"
        }
    , Tag
        { name = "text game"
        , slug = "text-game"
        }
    , Tag
        { name = "The Ants Parade"
        , slug = "the-ants-parade"
        }
    , Tag
        { name = "The Color and the Leaves"
        , slug = "the-color-and-the-leaves"
        }
    , Tag
        { name = "The Games Collective"
        , slug = "the-games-collective"
        }
    , Tag
        { name = "The Lake"
        , slug = "the-lake"
        }
    , Tag
        { name = "The tea room"
        , slug = "the-tea-room"
        }
    , Tag
        { name = "TIGSource"
        , slug = "tigsource"
        }
    , Tag
        { name = "timelapse"
        , slug = "timelapse"
        }
    , Tag
        { name = "tracker"
        , slug = "tracker"
        }
    , Tag
        { name = "translation"
        , slug = "translation"
        }
    , Tag
        { name = "Tumblecopter"
        , slug = "tumblecopter"
        }
    , Tag
        { name = "Twine"
        , slug = "twine"
        }
    , Tag
        { name = "university"
        , slug = "university"
        }
    , Tag
        { name = "video"
        , slug = "video"
        }
    , Tag
        { name = "video game"
        , slug = "video-game"
        }
    , Tag
        { name = "Viewpoints"
        , slug = "viewpoints"
        }
    , Tag
        { name = "Vine"
        , slug = "vine"
        }
    , Tag
        { name = "virtual reality"
        , slug = "virtual-reality"
        }
    , Tag
        { name = "visual novel"
        , slug = "visual-novel"
        }
    , Tag
        { name = "Walker"
        , slug = "walker"
        }
    , Tag
        { name = "web"
        , slug = "web"
        }
    , Tag
        { name = "Weekly concern"
        , slug = "weekly-concern"
        }
    , Tag
        { name = "While telling with the eyes"
        , slug = "while-telling-with-the-eyes"
        }
    , Tag
        { name = "Wirewalk"
        , slug = "wirewalk"
        }
    , Tag
        { name = "Within"
        , slug = "within"
        }
    , Tag
        { name = "writing"
        , slug = "writing"
        }
    , Tag
        { name = "日本語"
        , slug = "nihongo"
        }
    ]
