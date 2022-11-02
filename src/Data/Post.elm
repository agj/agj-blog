module Data.Post exposing (..)

import CustomMarkup
import Data.Language as Language exposing (Language)
import DataSource exposing (DataSource)
import DataSource.Glob as Glob exposing (Glob)
import Html exposing (Html)
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode
import Result.Extra as Result


type alias Post msg =
    { content : List (Html msg)
    , frontmatter : Frontmatter
    }


type alias Frontmatter =
    { id : Maybe Int
    , title : String
    , language : Language
    , categories : List String
    , tags : List String
    , date : Int
    , hour : Maybe Int
    }


postDecoder : String -> Decoder (Post msg)
postDecoder content =
    let
        parsedContent =
            content
                |> Markdown.Parser.parse
                |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
                |> Result.andThen (Markdown.Renderer.render CustomMarkup.renderer)
                |> Result.mapError CustomMarkup.renderErrorMessage
                |> Result.merge
    in
    frontmatterDecoder
        |> Decode.map (Post parsedContent)


frontmatterDecoder : Decoder Frontmatter
frontmatterDecoder =
    Decode.succeed Frontmatter
        |> Decode.required "id" (Decode.maybe Decode.int)
        |> Decode.required "title" Decode.string
        |> Decode.required "language" Language.decoder
        |> Decode.required "categories" (Decode.list Decode.string)
        |> Decode.required "tags" (Decode.list Decode.string)
        |> Decode.required "date" Decode.int
        |> Decode.required "hour" (Decode.maybe Decode.int)


type alias GlobMatch =
    { path : String
    , year : String
    , month : String
    , post : String
    , isHidden : Bool
    }


dataSource : DataSource (List GlobMatch)
dataSource =
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
