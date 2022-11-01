module Data.Post exposing (..)

import CustomMarkup
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
    , frontmatter : PostFrontmatter
    }


type alias PostFrontmatter =
    { id : Maybe Int
    , title : String
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
    postFrontmatterDecoder
        |> Decode.map (Post parsedContent)


postFrontmatterDecoder : Decoder PostFrontmatter
postFrontmatterDecoder =
    Decode.succeed PostFrontmatter
        |> Decode.required "id" (Decode.maybe Decode.int)
        |> Decode.required "title" Decode.string
        |> Decode.required "categories" (Decode.list Decode.string)
        |> Decode.required "tags" (Decode.list Decode.string)
        |> Decode.required "date" Decode.int
        |> Decode.required "hour" (Decode.maybe Decode.int)


type alias GlobMatch =
    { path : String
    , year : String
    , month : String
    , post : String

    -- , isHidden : Bool
    }


routesGlob : DataSource (List GlobMatch)
routesGlob =
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
        -- |> Glob.capture
        --     (Glob.oneOf
        --         ( ( "-HIDDEN.md", True )
        --         , [ ( ".md", False ) ]
        --         )
        --     )
        |> Glob.toDataSource
        |> DataSource.map (List.map (Debug.log "spy"))



-- |> DataSource.map (List.filter (.isHidden >> not))
