port module Ports exposing (listenQueryParamsChanges, saveConfig, setTheme)

import AppUrl exposing (QueryParameters)
import Dict exposing (Dict)
import Flags exposing (Flags)
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Theme exposing (Theme)



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
    listenIn "changedQueryParams" queryParamsDecoder onQueryParams onNoOp


queryParamsDecoder : Decoder QueryParameters
queryParamsDecoder =
    Json.Decode.dict (Json.Decode.list Json.Decode.string)



-- INTERNAL


type alias MsgValue a =
    { msg : String
    , value : a
    }


msgValueDecoder : Decoder value -> Decoder (MsgValue value)
msgValueDecoder valueDecoder =
    Json.Decode.map2 MsgValue
        (Json.Decode.field "msg" Json.Decode.string)
        (Json.Decode.field "value" valueDecoder)


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



-- PORTS


port sendToJs : Value -> Cmd msg


port receiveFromJs : (Value -> msg) -> Sub msg
