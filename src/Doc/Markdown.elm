module Doc.Markdown exposing
    ( AudioPlayerConfig
    , Config
    , parse
    )

import Doc
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import View.AudioPlayer
import View.AudioPlayer.Track
import View.LanguageBreak
import View.VideoEmbed


type alias Config msg =
    { audioPlayer : Maybe (AudioPlayerConfig msg)
    }


type alias AudioPlayerConfig msg =
    { onAudioPlayerStateUpdated : View.AudioPlayer.State -> msg
    }


type Intermediate msg
    = IntermediateBlock (Doc.Block msg)
    | IntermediateHeading Int (List Doc.Inline)
    | IntermediateInline Doc.Inline
    | IntermediateInlineList (List Doc.Inline)
    | IntermediateCustom Doc.Metadata


parse : Config msg -> String -> List (Doc.Block msg)
parse config markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render (renderer config))
        |> Result.map intermediatesToBlocks
        |> Result.mapError (\error -> [ Doc.Paragraph [ Doc.plainText error ] ])
        |> Result.merge


renderer : Config msg -> Markdown.Renderer.Renderer (Intermediate msg)
renderer config =
    { -- Inline
      text = Doc.plainText >> IntermediateInline
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
    , hardLineBreak = Doc.LineBreak |> IntermediateInline
    , image = renderImage
    , thematicBreak = Doc.Separation |> IntermediateBlock
    , html = renderCustom config.audioPlayer

    -- Table
    , table = \_ -> placeholderDoc
    , tableBody = \_ -> placeholderDoc
    , tableCell = \_ _ -> placeholderDoc
    , tableHeader = \_ -> placeholderDoc
    , tableHeaderCell = \_ _ -> placeholderDoc
    , tableRow = \_ -> placeholderDoc
    }


placeholderDoc : Intermediate msg
placeholderDoc =
    Doc.plainText "[Doc]"
        |> IntermediateInline


intermediatesToBlocks : List (Intermediate msg) -> List (Doc.Block msg)
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
                    IntermediateBlock block ->
                        ( sectionLevel
                        , block :: acc
                        )

                    IntermediateHeading incomingLevel inlines ->
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

                    IntermediateInline inline ->
                        ( sectionLevel
                        , Doc.Paragraph [ inline ] :: acc
                        )

                    IntermediateInlineList inlines ->
                        ( sectionLevel
                        , Doc.Paragraph inlines :: acc
                        )

                    IntermediateCustom _ ->
                        ( sectionLevel
                        , acc
                        )
            )
            ( 0, [] )
        |> Tuple.second



-- INLINE


renderInlineWithStyle : (Doc.Inline -> Doc.Inline) -> List (Intermediate msg) -> Intermediate msg
renderInlineWithStyle styler intermediates =
    intermediates
        |> List.filterMap
            (\intermediate ->
                case intermediate of
                    IntermediateInline inline ->
                        Just [ styler inline ]

                    IntermediateInlineList inlines ->
                        Just (inlines |> List.map styler)

                    _ ->
                        Nothing
            )
        |> List.concat
        |> IntermediateInlineList


renderLink : { title : Maybe String, destination : String } -> List (Intermediate msg) -> Intermediate msg
renderLink { destination } intermediates =
    intermediates
        |> unwrapInlines
        |> Doc.toLink destination
        |> IntermediateInline


renderInlineCode : String -> Intermediate msg
renderInlineCode code =
    Doc.inlineCode code
        |> IntermediateInline



-- BLOCK


renderParagraph : List (Intermediate msg) -> Intermediate msg
renderParagraph intermediates =
    case intermediates of
        (IntermediateBlock block) :: _ ->
            -- Images get put into paragraphs.
            IntermediateBlock block

        _ ->
            intermediates
                |> unwrapInlines
                |> Doc.Paragraph
                |> IntermediateBlock


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (Intermediate msg)
    }
    -> Intermediate msg
renderHeading { level, children } =
    IntermediateHeading
        (Markdown.Block.headingLevelToInt level)
        (unwrapInlines children)


renderUnorderedList : List (Markdown.Block.ListItem (Intermediate msg)) -> Intermediate msg
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
        |> IntermediateBlock


renderOrderedList : Int -> List (List (Intermediate msg)) -> Intermediate msg
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
        |> IntermediateBlock


renderBlockQuote : List (Intermediate msg) -> Intermediate msg
renderBlockQuote intermediates =
    intermediates
        |> ensureBlocks
        |> unwrapBlocks
        |> Doc.BlockQuote
        |> IntermediateBlock


renderCodeBlock : { body : String, language : Maybe String } -> Intermediate msg
renderCodeBlock { body, language } =
    Doc.CodeBlock { language = language, code = body }
        |> IntermediateBlock



-- SPECIAL


renderImage : { alt : String, src : String, title : Maybe String } -> Intermediate msg
renderImage { alt, src, title } =
    Doc.Image { url = src, description = alt, caption = title |> Maybe.withDefault "" }
        |> IntermediateBlock



-- CUSTOM


renderCustom : Maybe (AudioPlayerConfig msg) -> Markdown.Html.Renderer (List (Intermediate msg) -> Intermediate msg)
renderCustom audioPlayerConfig =
    Markdown.Html.oneOf (customRenderers audioPlayerConfig)


customRenderers : Maybe (AudioPlayerConfig msg) -> List (Markdown.Html.Renderer (List (Intermediate msg) -> Intermediate msg))
customRenderers audioPlayerConfig =
    let
        audioPlayerRenderers =
            case audioPlayerConfig of
                Just { onAudioPlayerStateUpdated } ->
                    [ View.AudioPlayer.Track.renderer
                        |> renderAsIntermediateCustom Doc.AudioPlayerTrack
                    , View.AudioPlayer.renderer
                        |> renderCustomWithCustomChildren
                            IntermediateBlock
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
                |> renderFailableCustom IntermediateBlock Doc.Video
            , View.LanguageBreak.renderer
                |> renderFailableCustom IntermediateBlock Doc.LanguageBreak
            ]
    in
    audioPlayerRenderers ++ otherCustomRenderers


renderFailableCustom :
    (Doc.Block msg -> Intermediate msg)
    -> (a -> Doc.Block msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List b -> Intermediate msg)
renderFailableCustom toIntermediate okToDoc customRenderer =
    customRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    renderErrorMessage err
                        |> IntermediateBlock
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
    -> Markdown.Html.Renderer (List b -> Intermediate msg)
renderAsIntermediateCustom toMetadata customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value _ ->
                toMetadata value
                    |> IntermediateCustom
            )


renderCustomWithCustomChildren :
    (Doc.Block msg -> Intermediate msg)
    -> (Doc.Metadata -> Maybe child)
    -> (value -> List child -> Doc.Block msg)
    -> Markdown.Html.Renderer value
    -> Markdown.Html.Renderer (List (Intermediate msg) -> Intermediate msg)
renderCustomWithCustomChildren toIntermediate metadataToChild toBlock customRenderer =
    let
        tagToChild tag =
            case tag of
                IntermediateCustom metadata ->
                    metadataToChild metadata

                _ ->
                    Nothing
    in
    customRenderer
        |> Markdown.Html.map
            (\value childrenTags ->
                let
                    children =
                        childrenTags
                            |> List.filterMap tagToChild
                in
                toBlock value children
                    |> toIntermediate
            )


renderErrorMessage : String -> Doc.Block msg
renderErrorMessage error =
    [ Doc.plainText "Parsing error: "
    , Doc.plainText error
    ]
        |> Doc.Paragraph



-- OTHER


unwrapInlines : List (Intermediate msg) -> List Doc.Inline
unwrapInlines intermediates =
    intermediates
        |> List.filterMap
            (\intermediate ->
                case intermediate of
                    IntermediateInline inline ->
                        Just [ inline ]

                    IntermediateInlineList inlines ->
                        Just inlines

                    IntermediateBlock _ ->
                        Nothing

                    IntermediateHeading _ _ ->
                        Nothing

                    IntermediateCustom _ ->
                        Nothing
            )
        |> List.concat


unwrapBlocks : List (Intermediate msg) -> List (Doc.Block msg)
unwrapBlocks =
    List.filterMap
        (\intermediate ->
            case intermediate of
                IntermediateBlock block ->
                    Just block

                _ ->
                    Nothing
        )


ensureBlocks : List (Intermediate msg) -> List (Intermediate msg)
ensureBlocks tags =
    let
        process :
            Intermediate msg
            -> ( List (Intermediate msg), List (Intermediate msg) )
            -> ( List (Intermediate msg), List (Intermediate msg) )
        process tag ( inlines, blocks ) =
            case tag of
                IntermediateInline _ ->
                    ( tag :: inlines, blocks )

                IntermediateInlineList _ ->
                    ( tag :: inlines, blocks )

                _ ->
                    ( [], tag :: wrapUpInlines ( inlines, blocks ) )

        wrapUpInlines :
            ( List (Intermediate msg), List (Intermediate msg) )
            -> List (Intermediate msg)
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
