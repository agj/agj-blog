module Data.Post exposing
    ( Post
    , PostGist
    , gistToUrl
    , gistsList
    , singleDataSource
    )

import BackendTask exposing (BackendTask)
import BackendTask.File exposing (FileReadError)
import BackendTask.Glob as Glob
import Custom.Int as Int
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Language as Language exposing (Language)
import Data.Tag as Tag exposing (Tag)
import Date exposing (Date)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Result.Extra
import Time
import Time.Extra
import TimeZone


type alias Post =
    { markdown : String
    , frontmatter : Frontmatter
    }


type alias PostGist =
    { id : Maybe Int
    , slug : String
    , title : String
    , language : Language
    , categories : List Category
    , tags : List Tag
    , date : Date
    , dateTime : Time.Posix
    , isHidden : Bool
    }


type alias Frontmatter =
    { id : Maybe Int
    , title : String
    , language : Language
    , categories : List Category
    , tags : List Tag
    , dayOfMonth : Int
    , dateTime : Maybe Time.Posix
    }


type alias GlobMatch =
    { path : String
    , yearString : String
    , monthString : String
    , slug : String
    , isHidden : Bool
    }


gistsList : BackendTask FatalError (List PostGist)
gistsList =
    listDataSource
        |> BackendTask.andThen
            (List.map globMatchWithFrontmatterToGist
                >> Result.Extra.combine
                >> Result.mapError FatalError.fromString
                >> BackendTask.fromResult
            )


singleDataSource :
    String
    -> String
    -> String
    -> BackendTask { fatal : FatalError, recoverable : FileReadError Decode.Error } Post
singleDataSource year month post =
    BackendTask.File.bodyWithFrontmatter postDecoder
        ("data/posts/{year}/{month}-{post}.md"
            |> String.replace "{year}" year
            |> String.replace "{month}" month
            |> String.replace "{post}" post
        )


gistToUrl : PostGist -> String
gistToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" (gist.date |> Date.year |> Int.padLeft 4)
        |> String.replace "{month}" (gist.date |> Date.monthNumber |> Int.padLeft 2)
        |> String.replace "{post}" gist.slug



-- INTERNAL


listDataSource : BackendTask FatalError (List ( GlobMatch, Frontmatter ))
listDataSource =
    Glob.succeed GlobMatch
        |> Glob.match (Glob.literal "data/posts/")
        -- Path
        |> Glob.captureFilePath
        -- Year
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "/")
        -- Month
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        -- Slug
        |> Glob.capture Glob.wildcard
        -- Hidden post flag
        |> Glob.capture
            (Glob.oneOf
                ( ( "-HIDDEN", True )
                , [ ( "", False ) ]
                )
            )
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.map (List.filter (.isHidden >> not))
        |> BackendTask.allowFatal
        |> BackendTask.andThen (List.map addFrontmatterToGlobMatch >> BackendTask.combine)


addFrontmatterToGlobMatch : GlobMatch -> BackendTask FatalError ( GlobMatch, Frontmatter )
addFrontmatterToGlobMatch match =
    BackendTask.File.onlyFrontmatter frontmatterDecoder match.path
        |> BackendTask.allowFatal
        |> BackendTask.map
            (\frontmatter -> ( match, frontmatter ))


globMatchWithFrontmatterToGist : ( GlobMatch, Frontmatter ) -> Result String PostGist
globMatchWithFrontmatterToGist ( post, frontmatter ) =
    let
        yearMaybe =
            post.yearString
                |> String.toInt

        monthMaybe =
            post.monthString
                |> String.toInt
                |> Maybe.map Date.intToMonth
    in
    case ( yearMaybe, monthMaybe ) of
        ( Just year, Just month ) ->
            let
                date =
                    Date.fromCalendarDate year month frontmatter.dayOfMonth

                dateTime =
                    case frontmatter.dateTime of
                        Just dt ->
                            dt

                        Nothing ->
                            Time.Extra.partsToPosix
                                (TimeZone.america__santiago ())
                                { year = year
                                , month = month
                                , day = frontmatter.dayOfMonth
                                , hour = 12
                                , minute = 0
                                , second = 0
                                , millisecond = 0
                                }
            in
            Result.Ok
                { id = frontmatter.id
                , title = frontmatter.title
                , slug = post.slug
                , language = frontmatter.language
                , categories = frontmatter.categories
                , tags = frontmatter.tags
                , date = date
                , dateTime = dateTime
                , isHidden = post.isHidden
                }

        _ ->
            Result.Err "Dates are incorrect."



-- DECODERS


postDecoder : String -> Decoder Post
postDecoder markdown =
    frontmatterDecoder
        |> Decode.map (Post markdown)


frontmatterDecoder : Decoder Frontmatter
frontmatterDecoder =
    Decode.succeed Frontmatter
        |> Decode.required "id" (Decode.maybe Decode.int)
        |> Decode.required "title" Decode.string
        |> Decode.required "language" Language.decoder
        |> Decode.required "categories" (Decode.list Category.decoder)
        |> Decode.required "tags" (Decode.list Tag.decoder)
        |> Decode.required "day-of-month" Decode.int
        |> Decode.optional "date"
            (Decode.string
                |> Decode.map Date.wordpressToPosix
            )
            Nothing
