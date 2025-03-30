port module Ports exposing (saveConfig, setTheme)

import Flags exposing (Flags)
import Json.Decode exposing (Value)
import Json.Encode
import Theme exposing (Theme)


saveConfig : Flags -> Cmd msg
saveConfig flags =
    sendOut "saveConfig" (Flags.encode flags)


setTheme : Theme -> Cmd msg
setTheme theme =
    sendOut "setTheme" (Theme.encode theme)



-- INTERNAL


sendOut : String -> Value -> Cmd msg
sendOut msg value =
    sendToJs
        (Json.Encode.object
            [ ( "msg", Json.Encode.string msg )
            , ( "value", value )
            ]
        )


port sendToJs : Value -> Cmd msg
