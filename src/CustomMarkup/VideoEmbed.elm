module CustomMarkup.VideoEmbed exposing
    ( VideoEmbed
    , VideoService(..)
    , renderer
    , stringToVideoService
    , toHtml
    )

import Html exposing (Html)
import Markdown.Html


type alias VideoEmbed =
    { id : String
    , service : VideoService
    , width : Int
    , height : Int
    }


type VideoService
    = Vimeo
    | Youtube


renderer : Markdown.Html.Renderer (Result String VideoEmbed)
renderer =
    Markdown.Html.tag "video-embed" constructVideoEmbed
        |> Markdown.Html.withAttribute "service"
        |> Markdown.Html.withAttribute "id"
        |> Markdown.Html.withAttribute "width"
        |> Markdown.Html.withAttribute "height"


toHtml : VideoEmbed -> List (Html msg) -> Html msg
toHtml videoEmbed children =
    Html.div []
        [ Html.text "Yes!" ]


stringToVideoService : String -> Result String VideoService
stringToVideoService str =
    case str of
        "vimeo" ->
            Ok Vimeo

        "youtube" ->
            Ok Youtube

        _ ->
            Err ("Unknown video service: " ++ str ++ ".")



-- INTERNAL


constructVideoEmbed : String -> String -> String -> String -> Result String VideoEmbed
constructVideoEmbed service id width height =
    Result.map4 VideoEmbed
        (Ok id)
        (stringToVideoService service)
        (String.toInt width |> Result.fromMaybe "Wrong width value.")
        (String.toInt height |> Result.fromMaybe "Wrong height value.")
