module Data.Language exposing (Language(..), decoder, fromString)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode


type Language
    = English
    | Spanish
    | Japanese
    | Mandarin


decoder : Decoder Language
decoder =
    Decode.string
        |> Decode.andThen (fromString >> Decode.fromResult)


fromString : String -> Result String Language
fromString str =
    case str of
        "eng" ->
            Ok English

        "spa" ->
            Ok Spanish

        "jpn" ->
            Ok Japanese

        "cnm" ->
            Ok Mandarin

        _ ->
            Err ("Unknown language: " ++ str ++ ".")
