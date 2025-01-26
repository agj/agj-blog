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
import Data.Language as Language exposing (Language)
import Data.Tag as Tag exposing (Tag)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode


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
    , date : Int
    , hour : Maybe Int
    }


type alias GlobMatch =
    { path : String
    , year : String
    , month : String
    , post : String
    , isHidden : Bool
    }


type alias GlobMatchFrontmatter =
    { path : String
    , year : String
    , month : String
    , post : String
    , isHidden : Bool
    , frontmatter : Frontmatter
    }


listDataSource : BackendTask { fatal : FatalError, recoverable : FileReadError Decode.Error } (List GlobMatch)
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


listWithFrontmatterDataSource : BackendTask { fatal : FatalError, recoverable : FileReadError Decode.Error } (List GlobMatchFrontmatter)
listWithFrontmatterDataSource =
    let
        processPost : GlobMatch -> BackendTask { fatal : FatalError, recoverable : FileReadError Decode.Error } GlobMatchFrontmatter
        processPost match =
            BackendTask.File.onlyFrontmatter frontmatterDecoder match.path
                |> BackendTask.map
                    (\frontmatter ->
                        { path = match.path
                        , year = match.year
                        , month = match.month
                        , post = match.post
                        , isHidden = match.isHidden
                        , frontmatter = frontmatter
                        }
                    )
    in
    listDataSource
        |> BackendTask.andThen (List.map processPost >> BackendTask.combine)


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
        |> String.replace "{year}" gist.year
        |> String.replace "{month}" gist.month
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
        |> Decode.required "date" Decode.int
        |> Decode.required "hour" (Decode.maybe Decode.int)
