module Effect exposing (Effect(..), batch, fromCmd, map, none, perform)

{-|

@docs Effect, batch, fromCmd, map, none, perform

-}

import Browser.Navigation
import Flags exposing (Flags)
import Form
import Http
import Pages.Fetcher
import Ports
import Theme exposing (Theme)
import Url exposing (Url)


{-| -}
type Effect msg
    = SaveConfig Flags
    | SetTheme Theme
    | None
    | Cmd (Cmd msg)
    | Batch (List (Effect msg))


{-| -}
none : Effect msg
none =
    None


{-| -}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| -}
fromCmd : Cmd msg -> Effect msg
fromCmd =
    Cmd


{-| -}
map : (a -> b) -> Effect a -> Effect b
map fn effect =
    case effect of
        SaveConfig flags ->
            SaveConfig flags

        SetTheme theme ->
            SetTheme theme

        None ->
            None

        Cmd cmd ->
            Cmd (Cmd.map fn cmd)

        Batch list ->
            Batch (List.map (map fn) list)


{-| -}
perform :
    { fetchRouteData :
        { data : Maybe FormData
        , toMsg : Result Http.Error Url -> pageMsg
        }
        -> Cmd msg
    , submit :
        { values : FormData
        , toMsg : Result Http.Error Url -> pageMsg
        }
        -> Cmd msg
    , runFetcher :
        Pages.Fetcher.Fetcher pageMsg
        -> Cmd msg
    , fromPageMsg : pageMsg -> msg
    , key : Browser.Navigation.Key
    , setField : { formId : String, name : String, value : String } -> Cmd msg
    }
    -> Effect pageMsg
    -> Cmd msg
perform ({ fromPageMsg, key } as helpers) effect =
    case effect of
        SaveConfig flags ->
            Ports.saveConfig flags

        SetTheme theme ->
            Ports.setTheme theme

        None ->
            Cmd.none

        Cmd cmd ->
            Cmd.map fromPageMsg cmd

        Batch list ->
            Cmd.batch (List.map (perform helpers) list)


type alias FormData =
    { fields : List ( String, String )
    , method : Form.Method
    , action : String
    , id : Maybe String
    }
