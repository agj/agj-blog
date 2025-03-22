module Theme exposing (Theme, ThemeColor(..), change, decoder, default, encode)

import Json.Decode exposing (Decoder, Value)
import Json.Encode


type alias Theme =
    { set : Maybe ThemeColor
    , default : ThemeColor
    }


type ThemeColor
    = Light
    | Dark


default : Theme
default =
    { set = Nothing
    , default = Light
    }


change : Theme -> Theme
change theme =
    let
        newSetTheme : Maybe ThemeColor
        newSetTheme =
            case ( theme.set, theme.default ) of
                -- Setting to opposite of default.
                ( Nothing, Light ) ->
                    Just Dark

                ( Nothing, Dark ) ->
                    Just Light

                -- Setting to forced default.
                ( Just Light, Dark ) ->
                    Just Dark

                ( Just Dark, Light ) ->
                    Just Light

                -- Unsetting.
                ( Just Light, Light ) ->
                    Nothing

                ( Just Dark, Dark ) ->
                    Nothing
    in
    { theme | set = newSetTheme }


decoder : Decoder Theme
decoder =
    Json.Decode.map2 Theme
        (Json.Decode.field "set" themeColorDecoder)
        (Json.Decode.field "default"
            (themeColorDecoder
                |> Json.Decode.map (Maybe.withDefault Light)
            )
        )


themeColorDecoder : Decoder (Maybe ThemeColor)
themeColorDecoder =
    Json.Decode.nullable Json.Decode.string
        |> Json.Decode.map
            (\maybeString ->
                case maybeString of
                    Just "light" ->
                        Just Light

                    Just "dark" ->
                        Just Dark

                    _ ->
                        Nothing
            )


encode : Theme -> Value
encode theme =
    case theme.set of
        Just themeColor ->
            encodeThemeColor themeColor

        Nothing ->
            Json.Encode.null


encodeThemeColor : ThemeColor -> Value
encodeThemeColor themeColor =
    case themeColor of
        Light ->
            Json.Encode.string "light"

        Dark ->
            Json.Encode.string "dark"
