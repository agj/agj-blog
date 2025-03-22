module Theme exposing (Theme(..), decoder, encode)

import Json.Decode exposing (Decoder, Value)
import Json.Encode


type Theme
    = Default Theme
    | Light
    | Dark


decoder : Decoder Theme
decoder =
    Json.Decode.string
        |> Json.Decode.map
            (\string ->
                case string of
                    "default-light" ->
                        Default Light

                    "default-dark" ->
                        Default Dark

                    "light" ->
                        Light

                    "dark" ->
                        Dark

                    _ ->
                        Default Light
            )


encode : Theme -> Value
encode theme =
    case theme of
        Default _ ->
            Json.Encode.null

        Light ->
            Json.Encode.string "light"

        Dark ->
            Json.Encode.string "dark"
