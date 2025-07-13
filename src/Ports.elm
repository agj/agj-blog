port module Ports exposing (listenDefaultThemeChange, listenQueryParamsChanges, saveConfig, setTheme)

import AppUrl exposing (QueryParameters)
import Flags exposing (Flags)
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Theme exposing (Theme, ThemeColor)
import Url



-- INCOMING


saveConfig : Flags -> Cmd msg
saveConfig flags =
    sendOut "saveConfig" (Flags.encode flags)


setTheme : Theme -> Cmd msg
setTheme theme =
    sendOut "setTheme" (Theme.encode theme)



-- OUTGOING


listenQueryParamsChanges : (QueryParameters -> msg) -> msg -> Sub msg
listenQueryParamsChanges onQueryParams onNoOp =
    let
        listener url =
            case Url.fromString url of
                Just u ->
                    AppUrl.fromUrl u
                        |> .queryParameters
                        |> onQueryParams

                Nothing ->
                    onNoOp
    in
    listenIn "urlChanged" Json.Decode.string listener onNoOp


listenDefaultThemeChange : (ThemeColor -> msg) -> msg -> Sub msg
listenDefaultThemeChange onThemeChange onNoOp =
    let
        listener maybeThemeColor =
            case maybeThemeColor of
                Just themeColor ->
                    onThemeChange themeColor

                Nothing ->
                    onNoOp
    in
    listenIn "defaultThemeChanged" Theme.themeColorDecoder listener onNoOp



-- INTERNAL


type alias MsgValue a =
    { msg : String
    , value : a
    }


sendOut : String -> Value -> Cmd msg
sendOut msg value =
    sendToJs
        (Json.Encode.object
            [ ( "msg", Json.Encode.string msg )
            , ( "value", value )
            ]
        )


listenIn : String -> Decoder value -> (value -> msg) -> msg -> Sub msg
listenIn msg valueDecoder toMsg noOpMsg =
    receiveFromJs
        (\raw ->
            Json.Decode.decodeValue (msgValueDecoder valueDecoder) raw
                |> Result.toMaybe
                |> Maybe.map
                    (\msgValue ->
                        if msgValue.msg == msg then
                            toMsg msgValue.value

                        else
                            noOpMsg
                    )
                |> Maybe.withDefault noOpMsg
        )



-- DECODERS


msgValueDecoder : Decoder value -> Decoder (MsgValue value)
msgValueDecoder valueDecoder =
    Json.Decode.map2 MsgValue
        (Json.Decode.field "msg" Json.Decode.string)
        (Json.Decode.field "value" valueDecoder)



-- PORTS


port sendToJs : Value -> Cmd msg


port receiveFromJs : (Value -> msg) -> Sub msg
