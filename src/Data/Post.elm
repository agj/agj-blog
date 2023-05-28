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

import Data.Category as Category exposing (Category)
import Data.Language as Language exposing (Language)
import Data.Tag as Tag exposing (Tag)
import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob exposing (Glob)
import Html exposing (Html)
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode


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


listDataSource : DataSource (List GlobMatch)
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
        |> Glob.toDataSource
        |> DataSource.map (List.filter (.isHidden >> not))


listWithFrontmatterDataSource : DataSource (List GlobMatchFrontmatter)
listWithFrontmatterDataSource =
    let
        processPost : GlobMatch -> DataSource GlobMatchFrontmatter
        processPost match =
            DataSource.File.onlyFrontmatter frontmatterDecoder match.path
                |> DataSource.map
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
        |> DataSource.andThen (List.map processPost >> DataSource.combine)


singleDataSource :
    String
    -> String
    -> String
    -> DataSource Post
singleDataSource year month post =
    DataSource.File.bodyWithFrontmatter postDecoder
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
