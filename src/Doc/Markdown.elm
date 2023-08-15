module Doc.Markdown exposing
    ( AudioPlayerConfig
    , Config
    , parse
    )

import Custom.List as List
import Doc
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import View.AudioPlayer
import View.AudioPlayer.Track exposing (Track)
import View.Column exposing (Spacing(..))
import View.LanguageBreak
import View.VideoEmbed


type alias Config msg =
    { audioPlayer : Maybe (AudioPlayerConfig msg)
    }


type alias AudioPlayerConfig msg =
    { onAudioPlayerStateUpdated : View.AudioPlayer.State -> msg
    }


parse : Config msg -> String -> List (Doc.Block msg)
parse config markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render (renderer config))
        |> Result.map intermediatesToBlocks
        |> Result.mapError (\error -> [ Doc.Paragraph [ Doc.plainText error ] ])
        |> Result.merge


intermediatesToBlocks : List (Doc.Intermediate msg) -> List (Doc.Block msg)
intermediatesToBlocks intermediates =
    let
        getForSection : List (Doc.Block msg) -> { forSection : List (Doc.Block msg), afterSection : List (Doc.Block msg) }
        getForSection blocks =
            blocks
                |> List.splitWhen Doc.isSection
                |> Maybe.map (\( before, after ) -> { forSection = before, afterSection = after })
                |> Maybe.withDefault { forSection = blocks, afterSection = [] }
    in
    intermediates
        |> List.foldr
            (\intermediate ( sectionLevel, acc ) ->
                case intermediate of
                    Doc.IntermediateBlock block ->
                        ( sectionLevel
                        , block :: acc
                        )

                    Doc.IntermediateHeading incomingLevel inlines ->
                        if incomingLevel >= sectionLevel then
                            -- Parallel section
                            let
                                { forSection, afterSection } =
                                    getForSection acc
                            in
                            ( incomingLevel
                            , Doc.Section { heading = inlines, content = forSection }
                                :: afterSection
                            )

                        else
                            -- Wrapping section
                            ( incomingLevel
                            , [ Doc.Section { heading = inlines, content = acc } ]
                            )

                    Doc.IntermediateInline inline ->
                        ( sectionLevel
                        , Doc.Paragraph [ inline ] :: acc
                        )

                    Doc.IntermediateInlineList inlines ->
                        ( sectionLevel
                        , Doc.Paragraph inlines :: acc
                        )

                    Doc.IntermediateCustom _ ->
                        ( sectionLevel
                        , acc
                        )
            )
            ( 0, [] )
        |> Tuple.second


renderer : Config msg -> Markdown.Renderer.Renderer (Doc.Intermediate msg)
renderer config =
    { -- Inline
      text = Doc.plainText >> Doc.IntermediateInline
    , strong = renderInlineWithStyle Doc.setBold
    , emphasis = renderInlineWithStyle Doc.setItalic
    , strikethrough = renderInlineWithStyle Doc.setStrikethrough
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
    , hardLineBreak = placeholderDoc
    , image = renderImage
    , thematicBreak = Doc.Separation |> Doc.IntermediateBlock
    , html = renderCustom config.audioPlayer

    -- Table
    , table = \_ -> placeholderDoc
    , tableBody = \_ -> placeholderDoc
    , tableCell = \_ _ -> placeholderDoc
    , tableHeader = \_ -> placeholderDoc
    , tableHeaderCell = \_ _ -> placeholderDoc
    , tableRow = \_ -> placeholderDoc
    }


placeholderDoc =
    Doc.plainText "[Doc]"
        |> Doc.IntermediateInline



-- INLINE


renderInlineWithStyle : (Doc.Inline -> Doc.Inline) -> List (Doc.Intermediate msg) -> Doc.Intermediate msg
renderInlineWithStyle styler intermediates =
    intermediates
        |> List.filterMap
            (\intermediate ->
                case intermediate of
                    Doc.IntermediateInline inline ->
                        Just [ styler inline ]

                    Doc.IntermediateInlineList inlines ->
                        Just (inlines |> List.map styler)

                    _ ->
                        Nothing
            )
        |> List.concat
        |> Doc.IntermediateInlineList


renderLink : { title : Maybe String, destination : String } -> List (Doc.Intermediate msg) -> Doc.Intermediate msg
renderLink { destination } intermediates =
    intermediates
        |> unwrapInlines
        |> Doc.toLink destination
        |> Doc.IntermediateInline


renderInlineCode : String -> Doc.Intermediate msg
renderInlineCode code =
    Doc.inlineCode code
        |> Doc.IntermediateInline



-- BLOCK


renderParagraph : List (Doc.Intermediate msg) -> Doc.Intermediate msg
renderParagraph intermediates =
    case intermediates of
        (Doc.IntermediateBlock block) :: _ ->
            -- Images get put into paragraphs.
            Doc.IntermediateBlock block

        _ ->
            intermediates
                |> unwrapInlines
                |> Doc.Paragraph
                |> Doc.IntermediateBlock


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (Doc.Intermediate msg)
    }
    -> Doc.Intermediate msg
renderHeading { level, children } =
    Doc.IntermediateHeading
        (Markdown.Block.headingLevelToInt level)
        (unwrapInlines children)


renderUnorderedList : List (Markdown.Block.ListItem (Doc.Intermediate msg)) -> Doc.Intermediate msg
renderUnorderedList items =
    let
        docListItems : List (Doc.ListItem msg)
        docListItems =
            items
                |> List.map
                    (\(Markdown.Block.ListItem task item) ->
                        item |> ensureBlocks |> unwrapBlocks
                    )
                |> List.filterMap List.uncons

        ( firstDocListItem, restDocListItems ) =
            docListItems
                |> List.uncons
                |> Maybe.withDefault
                    ( ( Doc.Paragraph [ Doc.plainText "" ], [] )
                    , []
                    )
    in
    Doc.UnorderedList firstDocListItem restDocListItems
        |> Doc.IntermediateBlock


renderOrderedList : Int -> List (List (Doc.Intermediate msg)) -> Doc.Intermediate msg
renderOrderedList startNumber items =
    let
        docListItems : List (Doc.ListItem msg)
        docListItems =
            items
                |> List.map (ensureBlocks >> unwrapBlocks)
                |> List.filterMap List.uncons

        ( firstDocListItem, restDocListItems ) =
            docListItems
                |> List.uncons
                |> Maybe.withDefault
                    ( ( Doc.Paragraph [ Doc.plainText "" ], [] )
                    , []
                    )
    in
    Doc.OrderedList firstDocListItem restDocListItems
        |> Doc.IntermediateBlock


renderBlockQuote : List (Doc.Intermediate msg) -> Doc.Intermediate msg
renderBlockQuote intermediates =
    intermediates
        |> ensureBlocks
        |> unwrapBlocks
        |> Doc.BlockQuote
        |> Doc.IntermediateBlock


renderCodeBlock : { body : String, language : Maybe String } -> Doc.Intermediate msg
renderCodeBlock { body, language } =
    Doc.CodeBlock { language = language, code = body }
        |> Doc.IntermediateBlock



-- SPECIAL


renderImage : { alt : String, src : String, title : Maybe String } -> Doc.Intermediate msg
renderImage { alt, src, title } =
    Doc.Image { url = src, description = alt }
        |> Doc.IntermediateBlock



-- CUSTOM


renderCustom : Maybe (AudioPlayerConfig msg) -> Markdown.Html.Renderer (List (Doc.Intermediate msg) -> Doc.Intermediate msg)
renderCustom audioPlayerConfig =
    Markdown.Html.oneOf (customRenderers audioPlayerConfig)


customRenderers : Maybe (AudioPlayerConfig msg) -> List (Markdown.Html.Renderer (List (Doc.Intermediate msg) -> Doc.Intermediate msg))
customRenderers audioPlayerConfig =
    let
        audioPlayerRenderers =
            case audioPlayerConfig of
                Just { onAudioPlayerStateUpdated } ->
                    [ View.AudioPlayer.Track.renderer
                        |> renderAsIntermediateCustom Doc.AudioPlayerTrack
                    , View.AudioPlayer.renderer
                        |> renderCustomWithCustomChildren
                            Doc.IntermediateBlock
                            (\metadata ->
                                case metadata of
                                    Doc.AudioPlayerTrack track ->
                                        Just track
                            )
                            (\audioPlayer tracks ->
                                audioPlayer
                                    |> View.AudioPlayer.withConfig
                                        { onStateUpdated = onAudioPlayerStateUpdated
                                        , tracks = tracks
                                        }
                                    |> Doc.AudioPlayer
                            )
                    ]

                Nothing ->
                    []

        otherCustomRenderers =
            [ View.VideoEmbed.renderer
                |> renderFailableCustom Doc.IntermediateBlock Doc.Video
            , View.LanguageBreak.renderer
                |> renderFailableCustom Doc.IntermediateBlock Doc.LanguageBreak
            ]
    in
    audioPlayerRenderers ++ otherCustomRenderers


renderFailableCustom :
    (Doc.Block msg -> Doc.Intermediate msg)
    -> (a -> Doc.Block msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List b -> Doc.Intermediate msg)
renderFailableCustom toIntermediate okToDoc customRenderer =
    customRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    renderErrorMessage err
                        |> Doc.IntermediateBlock
                )
                (\okResult _ ->
                    okToDoc okResult
                        |> toIntermediate
                )
            )
        |> Markdown.Html.map Result.merge


renderAsIntermediateCustom :
    (a -> Doc.Metadata)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (List b -> Doc.Intermediate msg)
renderAsIntermediateCustom toMetadata customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value _ ->
                toMetadata value
                    |> Doc.IntermediateCustom
            )


renderCustomWithCustomChildren :
    (Doc.Block msg -> Doc.Intermediate msg)
    -> (Doc.Metadata -> Maybe child)
    -> (value -> List child -> Doc.Block msg)
    -> Markdown.Html.Renderer value
    -> Markdown.Html.Renderer (List (Doc.Intermediate msg) -> Doc.Intermediate msg)
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
                                        Doc.IntermediateCustom metadata ->
                                            metadataToChild metadata

                                        _ ->
                                            Nothing
                                )
                in
                toElmUi_ value children
                    |> toElmUiTag
            )


renderErrorMessage : String -> Doc.Block msg
renderErrorMessage error =
    [ Doc.plainText "Parsing error: "
    , Doc.plainText error
    ]
        |> Doc.Paragraph



-- OTHER


unwrapInlines : List (Doc.Intermediate msg) -> List Doc.Inline
unwrapInlines intermediates =
    intermediates
        |> List.filterMap
            (\intermediate ->
                case intermediate of
                    Doc.IntermediateInline inline ->
                        Just [ inline ]

                    Doc.IntermediateInlineList inlines ->
                        Just inlines

                    Doc.IntermediateBlock _ ->
                        Nothing

                    Doc.IntermediateHeading _ _ ->
                        Nothing

                    Doc.IntermediateCustom _ ->
                        Nothing
            )
        |> List.concat


unwrapBlocks : List (Doc.Intermediate msg) -> List (Doc.Block msg)
unwrapBlocks =
    List.filterMap
        (\intermediate ->
            case intermediate of
                Doc.IntermediateBlock block ->
                    Just block

                _ ->
                    Nothing
        )


ensureBlocks : List (Doc.Intermediate msg) -> List (Doc.Intermediate msg)
ensureBlocks tags =
    let
        process :
            Doc.Intermediate msg
            -> ( List (Doc.Intermediate msg), List (Doc.Intermediate msg) )
            -> ( List (Doc.Intermediate msg), List (Doc.Intermediate msg) )
        process tag ( inlines, blocks ) =
            case tag of
                Doc.IntermediateInline _ ->
                    ( tag :: inlines, blocks )

                _ ->
                    ( [], tag :: wrapUpInlines ( inlines, blocks ) )

        wrapUpInlines :
            ( List (Doc.Intermediate msg), List (Doc.Intermediate msg) )
            -> List (Doc.Intermediate msg)
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
