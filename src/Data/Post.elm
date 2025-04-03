module Data.Post exposing
    ( Frontmatter
    , GlobMatch
    , GlobMatchFrontmatter
    , Post
    , globMatchFrontmatterToUrl
    , listDataSource
    , listWithFrontmatterDataSource
    , singleDataSource
    )

import BackendTask exposing (BackendTask)
import BackendTask.File exposing (FileReadError)
import BackendTask.Glob as Glob
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Language as Language exposing (Language)
import Data.Tag as Tag exposing (Tag)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Time


type alias Post =
    { markdown : String
    , frontmatter : Frontmatter
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
    , year : Int
    , monthString : String
    , month : Time.Month
    , post : String
    , isHidden : Bool
    }


type alias GlobMatchRaw =
    { path : String
    , yearString : String
    , monthString : String
    , post : String
    , isHidden : Bool
    }


type alias GlobMatchFrontmatter =
    { path : String
    , yearString : String
    , year : Int
    , monthString : String
    , month : Time.Month
    , post : String
    , isHidden : Bool
    , frontmatter : Frontmatter
    }


listDataSource : BackendTask FatalError (List GlobMatch)
listDataSource =
    Glob.succeed GlobMatchRaw
        |> Glob.match (Glob.literal "data/posts/")
        -- Path
        |> Glob.captureFilePath
        -- Year
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "/")
        -- Month
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        -- Post
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
        |> BackendTask.andThen
            (List.map
                (globMatchRawToGlobMatch
                    >> Maybe.map BackendTask.succeed
                    >> Maybe.withDefault (BackendTask.fail (FatalError.fromString "Wrong date in post."))
                )
                >> BackendTask.combine
            )


listWithFrontmatterDataSource : BackendTask FatalError (List GlobMatchFrontmatter)
listWithFrontmatterDataSource =
    let
        processPost : GlobMatch -> BackendTask FatalError GlobMatchFrontmatter
        processPost match =
            BackendTask.File.onlyFrontmatter frontmatterDecoder match.path
                |> BackendTask.allowFatal
                |> BackendTask.map
                    (\frontmatter ->
                        { path = match.path
                        , yearString = match.yearString
                        , year = match.year
                        , monthString = match.monthString
                        , month = match.month
                        , post = match.post
                        , isHidden = match.isHidden
                        , frontmatter = frontmatter
                        }
                    )
    in
    listDataSource
        |> BackendTask.andThen (List.map processPost >> BackendTask.combine)


globMatchRawToGlobMatch : GlobMatchRaw -> Maybe GlobMatch
globMatchRawToGlobMatch raw =
    let
        yearMaybe : Maybe Int
        yearMaybe =
            String.toInt raw.yearString

        monthMaybe : Maybe Time.Month
        monthMaybe =
            raw.monthString
                |> String.toInt
                |> Maybe.map Date.intToMonth
    in
    case ( yearMaybe, monthMaybe ) of
        ( Just year, Just month ) ->
            Just
                { path = raw.path
                , yearString = raw.yearString
                , year = year
                , monthString = raw.monthString
                , month = month
                , post = raw.post
                , isHidden = raw.isHidden
                }

        _ ->
            Nothing


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


globMatchFrontmatterToUrl : GlobMatchFrontmatter -> String
globMatchFrontmatterToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" gist.yearString
        |> String.replace "{month}" gist.monthString
        |> String.replace "{post}" gist.post



-- INTERNAL


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
