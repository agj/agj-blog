port module Ports exposing (..)

import Json.Decode exposing (Value)



-- OUTBOUND


port saveConfig : Value -> Cmd msg


port setTheme : Value -> Cmd msg
