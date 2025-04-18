module Data.Post exposing
    ( Post
    , PostGist
    , gistToUrl
    , gistsList
    , list
    , single
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
    , gist : PostGist
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
    , mastodonStatusId : Maybe String
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
    , mastodonStatusId : Maybe String
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
    globMatchList
        |> BackendTask.andThen (List.map addFrontmatterToGlobMatch >> BackendTask.combine)
        |> BackendTask.andThen
            (List.map globMatchWithFrontmatterToGist
                >> Result.Extra.combine
                >> Result.mapError FatalError.fromString
                >> BackendTask.fromResult
            )


list : BackendTask FatalError (List Post)
list =
    globMatchList
        |> BackendTask.andThen (List.map globMatchToPost >> BackendTask.combine)


single :
    String
    -> String
    -> String
    -> BackendTask { fatal : FatalError, recoverable : FileReadError Decode.Error } Post
single year month slug =
    BackendTask.File.bodyWithFrontmatter (postDecoder { year = year, month = month, slug = slug })
        ("data/posts/{year}/{month}-{post}.md"
            |> String.replace "{year}" year
            |> String.replace "{month}" month
            |> String.replace "{post}" slug
        )


gistToUrl : PostGist -> String
gistToUrl gist =
    "/{year}/{month}/{post}"
        |> String.replace "{year}" (gist.date |> Date.year |> Int.padLeft 4)
        |> String.replace "{month}" (gist.date |> Date.monthNumber |> Int.padLeft 2)
        |> String.replace "{post}" gist.slug



-- INTERNAL


globMatchList : BackendTask FatalError (List GlobMatch)
globMatchList =
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


globMatchToPost : GlobMatch -> BackendTask FatalError Post
globMatchToPost { yearString, monthString, slug } =
    BackendTask.File.bodyWithFrontmatter
        (postDecoder
            { year = yearString
            , month = monthString
            , slug = slug
            }
        )
        ("data/posts/{year}/{month}-{post}.md"
            |> String.replace "{year}" yearString
            |> String.replace "{month}" monthString
            |> String.replace "{post}" slug
        )
        |> BackendTask.allowFatal


addFrontmatterToGlobMatch : GlobMatch -> BackendTask FatalError ( GlobMatch, Frontmatter )
addFrontmatterToGlobMatch match =
    BackendTask.File.onlyFrontmatter frontmatterDecoder match.path
        |> BackendTask.allowFatal
        |> BackendTask.map
            (\frontmatter -> ( match, frontmatter ))


globMatchWithFrontmatterToGist : ( GlobMatch, Frontmatter ) -> Result String PostGist
globMatchWithFrontmatterToGist ( globMatch, frontmatter ) =
    let
        yearMaybe =
            globMatch.yearString
                |> String.toInt

        monthMaybe =
            globMatch.monthString
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
                , slug = globMatch.slug
                , language = frontmatter.language
                , categories = frontmatter.categories
                , tags = frontmatter.tags
                , date = date
                , dateTime = dateTime
                , mastodonStatusId = frontmatter.mastodonStatusId
                , isHidden = globMatch.isHidden
                }

        _ ->
            Result.Err "Dates are incorrect."



-- DECODERS


postDecoder :
    { year : String, month : String, slug : String }
    -> String
    -> Decoder Post
postDecoder { year, month, slug } markdown =
    frontmatterDecoder
        |> Decode.andThen
            (\frontmatter ->
                case
                    globMatchWithFrontmatterToGist
                        ( { path = ""
                          , yearString = year
                          , monthString = month
                          , slug = slug
                          , isHidden = False
                          }
                        , frontmatter
                        )
                of
                    Result.Ok gist ->
                        Decode.succeed gist

                    Result.Err err ->
                        Decode.fail err
            )
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
        |> Decode.optional "link-mastodon" (Decode.maybe Decode.string) Nothing
