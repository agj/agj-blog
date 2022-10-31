module Data.Post exposing (..)

import Html exposing (Html)
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)
import OptimizedDecoder.Pipeline as Decode
import Result.Extra as Result


type alias Post msg =
    { content : List (Html msg)
    , title : String
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
    Decode.succeed (Post parsedContent)
        |> Decode.required "title" Decode.string



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