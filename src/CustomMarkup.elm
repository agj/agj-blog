module CustomMarkup exposing
    ( toElmUi
    , toHtml
    )

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Element as Ui
import Element.Font as UiFont
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import View.Figure
import View.TextBlock


toElmUi : String -> Ui.Element msg
toElmUi markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render elmUiRenderer)
        |> Result.map (List.map Tuple.first)
        |> Result.mapError renderErrorMessageAsElmUi
        |> Result.merge
        |> Ui.column []


toHtml : String -> List (Html msg)
toHtml markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render htmlRenderer)
        |> Result.mapError renderErrorMessageAsHtml
        |> Result.merge



-- INTERNAL
-- Elm UI Rendering


type Tag
    = Block
    | Inline


elmUiRenderer : Markdown.Renderer.Renderer ( Ui.Element msg, Tag )
elmUiRenderer =
    let
        getChildren : List ( Ui.Element msg, Tag ) -> List (Ui.Element msg)
        getChildren =
            List.map Tuple.first
    in
    { blockQuote = \childTags -> ( Ui.row [] (getChildren childTags), Block )
    , codeBlock = \{ body, language } -> ( Ui.text body, Block )
    , codeSpan = \code -> ( Ui.text code, Inline )
    , emphasis =
        \childTags ->
            ( Ui.paragraph [ UiFont.italic ] (getChildren childTags)
            , Inline
            )
    , hardLineBreak = ( Ui.text "\n", Block )
    , heading =
        \{ level, rawText, children } ->
            let
                constructor =
                    case level of
                        Markdown.Block.H1 ->
                            View.TextBlock.heading1

                        Markdown.Block.H2 ->
                            View.TextBlock.heading2

                        Markdown.Block.H3 ->
                            View.TextBlock.heading3

                        Markdown.Block.H4 ->
                            View.TextBlock.heading4

                        Markdown.Block.H5 ->
                            View.TextBlock.heading5

                        Markdown.Block.H6 ->
                            View.TextBlock.heading6
            in
            ( constructor (getChildren children)
                |> View.TextBlock.view
            , Block
            )
    , html =
        Markdown.Html.oneOf
            [ CustomMarkup.VideoEmbed.renderer
                |> resultToElmUi CustomMarkup.VideoEmbed.toElmUi
            , CustomMarkup.LanguageBreak.renderer
                |> resultToElmUi CustomMarkup.LanguageBreak.toElmUi
            , CustomMarkup.AudioPlayer.renderer
                |> Markdown.Html.map
                    (\ap childTags ->
                        ( CustomMarkup.AudioPlayer.toElmUi ap (getChildren childTags)
                        , Block
                        )
                    )
            , CustomMarkup.AudioPlayer.Track.renderer
                |> Markdown.Html.map
                    (\track _ ->
                        ( CustomMarkup.AudioPlayer.Track.toElmUi track ()
                        , Block
                        )
                    )
            ]
    , image =
        \{ alt, src, title } ->
            ( Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
            , Block
            )
    , link =
        \{ title, destination } childTags ->
            ( Ui.link []
                { url = destination
                , label =
                    Ui.paragraph [] (getChildren childTags)
                }
            , Inline
            )
    , orderedList =
        \startNumber items ->
            ( items
                |> List.map (getChildren >> Ui.paragraph [])
                |> Ui.column []
            , Block
            )
    , paragraph =
        \childTags ->
            case childTags of
                [ ( child, Block ) ] ->
                    ( child, Block )

                _ ->
                    ( View.TextBlock.paragraph (getChildren childTags)
                        |> View.TextBlock.view
                    , Block
                    )
    , strikethrough =
        \childTags ->
            ( Ui.paragraph [ UiFont.strike ] (getChildren childTags)
            , Inline
            )
    , strong =
        \childTags ->
            ( Ui.paragraph [ UiFont.bold ] (getChildren childTags)
            , Inline
            )
    , table =
        \childTags ->
            ( Ui.column [] (getChildren childTags)
            , Block
            )
    , tableBody = \childTags -> ( Ui.column [] (getChildren childTags), Block )
    , tableCell = \mAlignment childTags -> ( Ui.paragraph [] (getChildren childTags), Block )
    , tableHeader = \childTags -> ( Ui.column [] (getChildren childTags), Block )
    , tableHeaderCell = \mAlignment childTags -> ( Ui.row [] (getChildren childTags), Block )
    , tableRow = \childTags -> ( Ui.row [] (getChildren childTags), Block )
    , text = \text -> ( Ui.text text, Inline )
    , thematicBreak = ( Ui.text "---", Block )
    , unorderedList =
        \items ->
            ( Ui.column []
                (items
                    |> List.map
                        (\(Markdown.Block.ListItem task childTags) ->
                            Ui.paragraph [] (getChildren childTags)
                        )
                )
            , Block
            )
    }


resultToElmUi :
    (a -> List (Ui.Element msg) -> Ui.Element msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List ( Ui.Element msg, Tag ) -> ( Ui.Element msg, Tag ))
resultToElmUi partialToHtml resultRenderer =
    resultRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    ( Ui.column [] (renderErrorMessageAsElmUi err)
                    , Block
                    )
                )
                (\a children ->
                    ( partialToHtml a (List.map Tuple.first children)
                    , Block
                    )
                )
            )
        |> Markdown.Html.map Result.merge


renderErrorMessageAsElmUi : String -> List (Ui.Element msg)
renderErrorMessageAsElmUi error =
    [ Ui.paragraph []
        [ Ui.text "Parsing error:" ]
    , Ui.text error
    ]



-- HTML Rendering


htmlRenderer : Markdown.Renderer.Renderer (Html msg)
htmlRenderer =
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


renderErrorMessageAsHtml : String -> List (Html msg)
renderErrorMessageAsHtml error =
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
                (\err _ -> Html.div [] (renderErrorMessageAsHtml err))
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
