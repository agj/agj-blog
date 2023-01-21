module CustomMarkup exposing (toHtml)

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result


toHtml : String -> List (Html msg)
toHtml markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render renderer)
        |> Result.mapError renderErrorMessage
        |> Result.merge



-- INTERNAL


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    let
        defRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defRenderer
        | html =
            Markdown.Html.oneOf
                [ CustomMarkup.VideoEmbed.renderer
                    |> resultToHtml CustomMarkup.VideoEmbed.toHtml
                , CustomMarkup.LanguageBreak.renderer
                    |> resultToHtml CustomMarkup.LanguageBreak.toHtml
                , CustomMarkup.AudioPlayer.renderer
                    |> Markdown.Html.map CustomMarkup.AudioPlayer.toHtml
                , CustomMarkup.AudioPlayer.Track.renderer
                    |> Markdown.Html.map CustomMarkup.AudioPlayer.Track.toHtml
                ]
        , heading = renderHeading
        , image = renderImage
    }


renderErrorMessage : String -> List (Html msg)
renderErrorMessage error =
    [ Html.p []
        [ Html.text "Parsing error:"
        ]
    , Html.pre []
        [ Html.code [] [ Html.text error ]
        ]
    ]


resultToHtml :
    (a -> List (Html msg) -> Html msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List (Html msg) -> Html msg)
resultToHtml partialToHtml resultRenderer =
    resultRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ -> Html.div [] (renderErrorMessage err))
                partialToHtml
            )
        |> Markdown.Html.map Result.merge


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (Html msg)
    }
    -> Html msg
renderHeading { level, rawText, children } =
    case level of
        Markdown.Block.H1 ->
            Html.h2 [] children

        Markdown.Block.H2 ->
            Html.h3 [] children

        Markdown.Block.H3 ->
            Html.h4 [] children

        Markdown.Block.H4 ->
            Html.h5 [] children

        Markdown.Block.H5 ->
            Html.h6 [] children

        Markdown.Block.H6 ->
            Html.p []
                [ Html.strong [] children
                ]


renderImage : { alt : String, src : String, title : Maybe String } -> Html msg
renderImage { alt, src, title } =
    let
        figcaption =
            case title of
                Just t ->
                    [ Html.figcaption [] [ Html.text t ] ]

                Nothing ->
                    []
    in
    Html.figure []
        (Html.img
            [ Attr.src src
            , Attr.alt alt
            ]
            []
            :: figcaption
        )
