module CustomMarkup exposing (toElmUi)

import Custom.Color as Color
import CustomMarkup.ElmUiTag as ElmUiTag exposing (ElmUiTag)
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Element.Font as UiFont
import Html
import Html.Attributes
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import Style
import View.AudioPlayer
import View.AudioPlayer.Track exposing (Track)
import View.CodeBlock
import View.Column exposing (Spacing(..))
import View.Figure
import View.Heading
import View.Inline
import View.LanguageBreak
import View.List
import View.Paragraph
import View.VideoEmbed


type alias Config msg =
    { audioPlayer : Maybe (AudioPlayerConfig msg)
    }


type alias AudioPlayerConfig msg =
    { audioPlayerState : View.AudioPlayer.State
    , onAudioPlayerStateUpdated : View.AudioPlayer.State -> msg
    }


toElmUi : Config msg -> String -> Ui.Element msg
toElmUi config markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render (renderer config))
        |> Result.map getElements
        |> Result.mapError renderErrorMessage
        |> Result.merge
        |> View.Column.setSpaced MSpacing



-- INTERNAL


renderer : Config msg -> Markdown.Renderer.Renderer (ElmUiTag msg)
renderer config =
    { -- Inline
      text = \text -> Ui.text text |> ElmUiTag.Inline
    , strong = renderInlineWithStyle View.Inline.setBold
    , emphasis = renderInlineWithStyle View.Inline.setItalic
    , strikethrough = renderInlineWithStyle View.Inline.setStrikethrough
    , link = renderLink
    , codeSpan = renderInlineCode

    -- Block
    , paragraph = renderParagraph
    , heading = renderHeading
    , unorderedList = renderUnorderedList
    , orderedList = renderOrderedList
    , blockQuote = renderBlockQuote
    , codeBlock = renderCodeBlock

    -- Special
    , hardLineBreak = Ui.text "\n" |> ElmUiTag.Block
    , image =
        \{ alt, src, title } ->
            Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
                |> ElmUiTag.Block
    , thematicBreak = Ui.text "---" |> ElmUiTag.Block
    , html = renderCustom config.audioPlayer

    -- Table
    , table =
        \tags ->
            Ui.column [] (unwrapInlines tags)
                |> ElmUiTag.Block
    , tableBody = \tags -> Ui.column [] (unwrapInlines tags) |> ElmUiTag.Block
    , tableCell = \mAlignment tags -> Ui.paragraph [] (unwrapInlines tags) |> ElmUiTag.Block
    , tableHeader = \tags -> Ui.column [] (unwrapInlines tags) |> ElmUiTag.Block
    , tableHeaderCell = \mAlignment tags -> Ui.row [] (unwrapInlines tags) |> ElmUiTag.Block
    , tableRow = \tags -> Ui.row [] (unwrapInlines tags) |> ElmUiTag.Block
    }



-- INLINE


renderInlineWithStyle : (List (Ui.Element msg) -> Ui.Element msg) -> List (ElmUiTag msg) -> ElmUiTag msg
renderInlineWithStyle styler tags =
    tags
        |> unwrapInlines
        |> styler
        |> ElmUiTag.Inline


renderLink : { title : Maybe String, destination : String } -> List (ElmUiTag msg) -> ElmUiTag msg
renderLink { destination } tags =
    tags
        |> unwrapInlines
        |> View.Inline.setLink destination
        |> ElmUiTag.Inline


renderInlineCode : String -> ElmUiTag msg
renderInlineCode code =
    View.Inline.setCode code
        |> ElmUiTag.Inline



-- BLOCK


renderParagraph : List (ElmUiTag msg) -> ElmUiTag msg
renderParagraph tags =
    tags
        |> unwrapInlines
        |> View.Paragraph.view
        |> ElmUiTag.Block


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (ElmUiTag msg)
    }
    -> ElmUiTag msg
renderHeading { level, children } =
    children
        |> unwrapInlines
        |> View.Heading.view (Markdown.Block.headingLevelToInt level + 1)
        |> ElmUiTag.Block


renderUnorderedList : List (Markdown.Block.ListItem (ElmUiTag msg)) -> ElmUiTag msg
renderUnorderedList items =
    items
        |> List.map
            (\(Markdown.Block.ListItem task item) ->
                item |> ensureBlocks |> unwrapBlocks
            )
        |> View.List.fromItems
        |> View.List.view
        |> ElmUiTag.Block


renderOrderedList : Int -> List (List (ElmUiTag msg)) -> ElmUiTag msg
renderOrderedList startNumber items =
    items
        |> List.map (ensureBlocks >> unwrapBlocks)
        |> View.List.fromItems
        |> View.List.withNumbers startNumber
        |> View.List.view
        |> ElmUiTag.Block


renderBlockQuote : List (ElmUiTag msg) -> ElmUiTag msg
renderBlockQuote tags =
    let
        line =
            Ui.el
                [ Ui.width (Ui.px Style.spacing.size1)
                , Ui.height Ui.fill
                , UiBackground.color (Style.color.secondary10 |> Color.toElmUi)
                , Ui.alignLeft
                ]
                Ui.none

        side =
            Ui.el
                [ Ui.width (Ui.px Style.spacing.size6)
                , Ui.height Ui.fill
                ]
                line

        toQuote : Ui.Element msg -> Ui.Element msg
        toQuote content =
            Ui.row [ Ui.width Ui.fill ]
                [ side
                , content
                ]
    in
    tags
        |> ensureBlocks
        |> unwrapBlocks
        |> View.Column.setSpaced MSpacing
        |> toQuote
        |> ElmUiTag.Block


renderCodeBlock : { body : String, language : Maybe String } -> ElmUiTag msg
renderCodeBlock { body, language } =
    View.CodeBlock.fromBody language body
        |> View.CodeBlock.view
        |> ElmUiTag.Block



-- CUSTOM


renderCustom : Maybe (AudioPlayerConfig msg) -> Markdown.Html.Renderer (List (ElmUiTag msg) -> ElmUiTag msg)
renderCustom audioPlayerConfig =
    Markdown.Html.oneOf (customRenderers audioPlayerConfig)


customRenderers : Maybe (AudioPlayerConfig msg) -> List (Markdown.Html.Renderer (List (ElmUiTag msg) -> ElmUiTag msg))
customRenderers audioPlayerConfig =
    let
        audioPlayerRenderers =
            case audioPlayerConfig of
                Just { audioPlayerState, onAudioPlayerStateUpdated } ->
                    [ View.AudioPlayer.Track.renderer
                        |> renderAsTagCustom ElmUiTag.AudioPlayerTrack
                    , View.AudioPlayer.renderer
                        |> renderCustomWithCustomChildren
                            ElmUiTag.Block
                            (\metadata ->
                                case metadata of
                                    ElmUiTag.AudioPlayerTrack track ->
                                        Just track
                            )
                            (\audioPlayer tracks ->
                                audioPlayer
                                    |> View.AudioPlayer.withConfig
                                        { onStateUpdated = onAudioPlayerStateUpdated
                                        , tracks = tracks
                                        }
                                    |> View.AudioPlayer.view audioPlayerState
                            )
                    ]

                Nothing ->
                    []

        otherCustomRenderers =
            [ View.VideoEmbed.renderer
                |> renderFailableCustom ElmUiTag.Block View.VideoEmbed.view
            , View.LanguageBreak.renderer
                |> renderFailableCustom ElmUiTag.Block View.LanguageBreak.view
            ]
    in
    audioPlayerRenderers ++ otherCustomRenderers


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


renderAsTagCustom :
    (a -> ElmUiTag.Metadata)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (List b -> ElmUiTag msg)
renderAsTagCustom toMetadata customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value _ ->
                toMetadata value
                    |> ElmUiTag.Custom
            )


renderCustomWithCustomChildren :
    (Ui.Element msg -> ElmUiTag msg)
    -> (ElmUiTag.Metadata -> Maybe child)
    -> (value -> List child -> Ui.Element msg)
    -> Markdown.Html.Renderer value
    -> Markdown.Html.Renderer (List (ElmUiTag msg) -> ElmUiTag msg)
renderCustomWithCustomChildren toElmUiTag metadataToChild toElmUi_ customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value childrenTags ->
                let
                    children =
                        childrenTags
                            |> List.filterMap
                                (\tag ->
                                    case tag of
                                        ElmUiTag.Custom metadata ->
                                            metadataToChild metadata

                                        _ ->
                                            Nothing
                                )
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



-- OTHER


unwrapInlines : List (ElmUiTag msg) -> List (Ui.Element msg)
unwrapInlines =
    List.filterMap
        (\tag ->
            case tag of
                ElmUiTag.Inline element ->
                    Just element

                _ ->
                    Nothing
        )


unwrapBlocks : List (ElmUiTag msg) -> List (Ui.Element msg)
unwrapBlocks =
    List.filterMap
        (\tag ->
            case tag of
                ElmUiTag.Block element ->
                    Just element

                _ ->
                    Nothing
        )


ensureBlocks : List (ElmUiTag msg) -> List (ElmUiTag msg)
ensureBlocks tags =
    let
        process : ElmUiTag msg -> ( List (ElmUiTag msg), List (ElmUiTag msg) ) -> ( List (ElmUiTag msg), List (ElmUiTag msg) )
        process tag ( inlines, blocks ) =
            case tag of
                ElmUiTag.Inline _ ->
                    ( tag :: inlines, blocks )

                _ ->
                    ( [], tag :: wrapUpInlines ( inlines, blocks ) )

        wrapUpInlines : ( List (ElmUiTag msg), List (ElmUiTag msg) ) -> List (ElmUiTag msg)
        wrapUpInlines ( inlines, blocks ) =
            case inlines of
                [] ->
                    blocks

                _ :: _ ->
                    renderParagraph inlines :: blocks
    in
    tags
        |> List.foldr process ( [], [] )
        |> wrapUpInlines


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
