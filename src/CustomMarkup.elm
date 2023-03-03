module CustomMarkup exposing (toElmUi)

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.ElmUiTag as ElmUiTag exposing (ElmUiTag)
import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Element as Ui
import Element.Font as UiFont
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
        |> Result.andThen (Markdown.Renderer.render renderer)
        |> Result.map getElements
        |> Result.mapError renderErrorMessage
        |> Result.merge
        |> Ui.column []



-- INTERNAL


renderer : Markdown.Renderer.Renderer (ElmUiTag msg)
renderer =
    { blockQuote = \tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    , codeBlock = \{ body, language } -> Ui.text body |> ElmUiTag.Block
    , codeSpan = \code -> Ui.text code |> ElmUiTag.Inline
    , emphasis = renderInlineWithStyle UiFont.italic
    , hardLineBreak = Ui.text "\n" |> ElmUiTag.Block
    , heading = renderHeading
    , html =
        Markdown.Html.oneOf
            [ CustomMarkup.VideoEmbed.renderer
                |> renderFailableCustom ElmUiTag.Block CustomMarkup.VideoEmbed.toElmUi
            , CustomMarkup.LanguageBreak.renderer
                |> renderFailableCustom ElmUiTag.Block CustomMarkup.LanguageBreak.toElmUi
            , CustomMarkup.AudioPlayer.Track.renderer
                |> renderNonRenderingCustom (ElmUiTag.AudioPlayerTrack >> ElmUiTag.Custom)
            , CustomMarkup.AudioPlayer.renderer
                |> renderCustomWithCustomChildren
                    ElmUiTag.Block
                    (\tag ->
                        case tag of
                            ElmUiTag.Custom (ElmUiTag.AudioPlayerTrack track) ->
                                Just track

                            _ ->
                                Nothing
                    )
                    CustomMarkup.AudioPlayer.toElmUi
            ]
    , image =
        \{ alt, src, title } ->
            Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
                |> ElmUiTag.Block
    , link =
        \{ title, destination } tags ->
            Ui.link []
                { url = destination
                , label =
                    Ui.paragraph [] (getInlines tags)
                }
                |> ElmUiTag.Inline
    , orderedList =
        \startNumber items ->
            items
                |> List.map (getInlines >> Ui.paragraph [])
                |> Ui.column []
                |> ElmUiTag.Block
    , paragraph = renderParagraph
    , strikethrough = renderInlineWithStyle UiFont.strike
    , strong = renderInlineWithStyle UiFont.bold
    , table =
        \tags ->
            Ui.column [] (getInlines tags)
                |> ElmUiTag.Block
    , tableBody = \tags -> Ui.column [] (getInlines tags) |> ElmUiTag.Block
    , tableCell = \mAlignment tags -> Ui.paragraph [] (getInlines tags) |> ElmUiTag.Block
    , tableHeader = \tags -> Ui.column [] (getInlines tags) |> ElmUiTag.Block
    , tableHeaderCell = \mAlignment tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    , tableRow = \tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    , text = \text -> Ui.text text |> ElmUiTag.Inline
    , thematicBreak = Ui.text "---" |> ElmUiTag.Block
    , unorderedList =
        \items ->
            Ui.column []
                (items
                    |> List.map
                        (\(Markdown.Block.ListItem task tags) ->
                            Ui.paragraph [] (getInlines tags)
                        )
                )
                |> ElmUiTag.Block
    }


renderInlineWithStyle : Ui.Attribute msg -> List (ElmUiTag msg) -> ElmUiTag msg
renderInlineWithStyle attr tags =
    Ui.paragraph [ attr ] (getInlines tags)
        |> ElmUiTag.Inline


renderParagraph : List (ElmUiTag msg) -> ElmUiTag msg
renderParagraph tags =
    case tags of
        [ ElmUiTag.Block element ] ->
            ElmUiTag.Block element

        _ ->
            View.TextBlock.paragraph (getInlines tags)
                |> View.TextBlock.view
                |> ElmUiTag.Block


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (ElmUiTag msg)
    }
    -> ElmUiTag msg
renderHeading { level, rawText, children } =
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
    constructor (getInlines children)
        |> View.TextBlock.view
        |> ElmUiTag.Block


renderFailableCustom :
    (Ui.Element msg -> ElmUiTag msg)
    -> (a -> Ui.Element msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List b -> ElmUiTag msg)
renderFailableCustom toElmUiTag okToElmUi customRenderer =
    customRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    Ui.column [] (renderErrorMessage err)
                        |> ElmUiTag.Block
                )
                (\okResult _ ->
                    okToElmUi okResult
                        |> toElmUiTag
                )
            )
        |> Markdown.Html.map Result.merge


renderNonRenderingCustom :
    (a -> ElmUiTag msg)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (List b -> ElmUiTag msg)
renderNonRenderingCustom toElmUiTag customRenderer =
    customRenderer
        |> Markdown.Html.map (\value _ -> toElmUiTag value)


renderCustomWithCustomChildren :
    (Ui.Element msg -> ElmUiTag msg)
    -> (ElmUiTag msg -> Maybe child)
    -> (value -> List child -> Ui.Element msg)
    -> Markdown.Html.Renderer value
    -> Markdown.Html.Renderer (List (ElmUiTag msg) -> ElmUiTag msg)
renderCustomWithCustomChildren toElmUiTag tagToChild toElmUi_ customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value childrenTags ->
                let
                    children =
                        childrenTags
                            |> List.filterMap tagToChild
                in
                toElmUi_ value children
                    |> toElmUiTag
            )


renderErrorMessage : String -> List (Ui.Element msg)
renderErrorMessage error =
    [ Ui.paragraph []
        [ Ui.text "Parsing error:" ]
    , Ui.text error
    ]


getInlines : List (ElmUiTag msg) -> List (Ui.Element msg)
getInlines =
    List.filterMap
        (\tag ->
            case tag of
                ElmUiTag.Inline element ->
                    Just element

                _ ->
                    Nothing
        )


getBlocks : List (ElmUiTag msg) -> List (Ui.Element msg)
getBlocks =
    List.filterMap
        (\tag ->
            case tag of
                ElmUiTag.Block element ->
                    Just element

                _ ->
                    Nothing
        )


getElements : List (ElmUiTag msg) -> List (Ui.Element msg)
getElements =
    List.filterMap
        (\tag ->
            case tag of
                ElmUiTag.Block element ->
                    Just element

                ElmUiTag.Inline element ->
                    Just element

                ElmUiTag.Custom _ ->
                    Nothing
        )
