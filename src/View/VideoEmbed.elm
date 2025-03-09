module View.VideoEmbed exposing
    ( VideoEmbed
    , VideoService(..)
    , renderer
    , view
    )

import Html exposing (Html)
import Html.Attributes
import Markdown.Html
import View.Figure


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


view : VideoEmbed -> Html msg
view videoEmbed =
    let
        src =
            case videoEmbed.service of
                Vimeo ->
                    let
                        params =
                            [ { key = "byline", value = "0" }
                            , { key = "portrait", value = "0" }
                            ]
                    in
                    "https://player.vimeo.com/video/{id}?{params}"
                        |> String.replace "{id}" videoEmbed.id
                        |> String.replace "{params}" (parseParameters params)

                Youtube ->
                    let
                        params =
                            [ { key = "rel", value = "0" }
                            ]
                    in
                    "https://www.youtube-nocookie.com/embed/{id}?{params}"
                        |> String.replace "{id}" videoEmbed.id
                        |> String.replace "{params}" (parseParameters params)

        iframe =
            Html.iframe
                [ Html.Attributes.src src
                , Html.Attributes.attribute "frameborder" "0"
                , Html.Attributes.attribute "allowfullscreen" "allowfullscreen"
                , Html.Attributes.style "width" ((videoEmbed.width |> String.fromInt) ++ "px")
                , Html.Attributes.style "height" ((videoEmbed.height |> String.fromInt) ++ "px")
                ]
                []
    in
    View.Figure.figure iframe
        |> View.Figure.view



-- INTERNAL


constructVideoEmbed : String -> String -> String -> String -> Result String VideoEmbed
constructVideoEmbed service id width height =
    Result.map4 VideoEmbed
        (Ok id)
        (stringToVideoService service)
        (String.toInt width |> Result.fromMaybe "Wrong width value.")
        (String.toInt height |> Result.fromMaybe "Wrong height value.")


stringToVideoService : String -> Result String VideoService
stringToVideoService str =
    case str of
        "vimeo" ->
            Ok Vimeo

        "youtube" ->
            Ok Youtube

        _ ->
            Err ("Unknown video service: " ++ str ++ ".")


parseParameters : List { key : String, value : String } -> String
parseParameters params =
    let
        toString param =
            param.key
                ++ "="
                ++ param.value
    in
    params
        |> List.map toString
        |> String.join "&"
