module Data.Post exposing (..)

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
    { title : String
    , categories : List String
    , tags : List String
    , date : Maybe Int
    , hour : Maybe Int
    }


postDecoder : String -> Decoder (Post msg)
postDecoder content =
    let
        parsedContent =
            content
                |> Markdown.Parser.parse
                |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
                |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
                |> Result.mapError errorToHtml
                |> Result.merge
    in
    postFrontmatterDecoder
        |> Decode.map (Post parsedContent)


postFrontmatterDecoder : Decoder PostFrontmatter
postFrontmatterDecoder =
    Decode.succeed PostFrontmatter
        |> Decode.required "title" Decode.string
        |> Decode.required "categories" (Decode.list Decode.string)
        |> Decode.required "tags" (Decode.list Decode.string)
        |> Decode.required "date" (Decode.maybe Decode.int)
        |> Decode.required "hour" (Decode.maybe Decode.int)


routesGlob : Glob (String -> String -> String -> c) -> Glob c
routesGlob glob =
    glob
        |> Glob.match (Glob.literal "data/posts/")
        -- Year
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "/")
        -- Month
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        -- Slug
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")



-- INTERNAL


errorToHtml : String -> List (Html msg)
errorToHtml error =
    [ Html.p []
        [ Html.text "Markdown parsing error:"
        ]
    , Html.pre []
        [ Html.code [] [ Html.text error ]
        ]
    ]
