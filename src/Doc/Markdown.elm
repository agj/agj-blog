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


type alias Config msg =
    { audioPlayer : Maybe (AudioPlayerConfig msg)
    }


type alias AudioPlayerConfig msg =
    { audioPlayerState : View.AudioPlayer.State
    , onAudioPlayerStateUpdated : View.AudioPlayer.State -> msg
    }


parse : Config msg -> String -> List Doc.Block
parse config markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render (docRenderer config))
        |> Result.map intermediatesToBlocks
        |> Result.mapError (\error -> [ Doc.Paragraph [ Doc.plainText error ] ])
        |> Result.merge


intermediatesToBlocks : List Doc.Intermediate -> List Doc.Block
intermediatesToBlocks intermediates =
    let
        getForSection : List Doc.Block -> { forSection : List Doc.Block, afterSection : List Doc.Block }
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


docRenderer : Config msg -> Markdown.Renderer.Renderer Doc.Intermediate
docRenderer config =
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
    , blockQuote = \_ -> placeholderDoc
    , codeBlock = renderCodeBlock

    -- Special
    , hardLineBreak = placeholderDoc
    , image = renderImage
    , thematicBreak = placeholderDoc
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


renderInlineWithStyle : (Doc.Inline -> Doc.Inline) -> List Doc.Intermediate -> Doc.Intermediate
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


renderLink : { title : Maybe String, destination : String } -> List Doc.Intermediate -> Doc.Intermediate
renderLink { destination } intermediates =
    intermediates
        |> unwrapInlines
        |> Doc.toLink destination
        |> Doc.IntermediateInline


renderInlineCode : String -> Doc.Intermediate
renderInlineCode code =
    Doc.inlineCode code
        |> Doc.IntermediateInline



-- BLOCK


renderParagraph : List Doc.Intermediate -> Doc.Intermediate
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
    , children : List Doc.Intermediate
    }
    -> Doc.Intermediate
renderHeading { level, children } =
    Doc.IntermediateHeading
        (Markdown.Block.headingLevelToInt level)
        (unwrapInlines children)


renderUnorderedList : List (Markdown.Block.ListItem Doc.Intermediate) -> Doc.Intermediate
renderUnorderedList items =
    let
        docListItems : List Doc.ListItem
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


renderOrderedList : Int -> List (List Doc.Intermediate) -> Doc.Intermediate
renderOrderedList startNumber items =
    let
        docListItems : List Doc.ListItem
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


renderCodeBlock : { body : String, language : Maybe String } -> Doc.Intermediate
renderCodeBlock { body, language } =
    Doc.CodeBlock { language = language, code = body }
        |> Doc.IntermediateBlock



-- SPECIAL


renderImage : { alt : String, src : String, title : Maybe String } -> Doc.Intermediate
renderImage { alt, src, title } =
    Doc.Image { url = src, description = alt }
        |> Doc.IntermediateBlock



-- CUSTOM


renderCustom : Maybe (AudioPlayerConfig msg) -> Markdown.Html.Renderer (List Doc.Intermediate -> Doc.Intermediate)
renderCustom audioPlayerConfig =
    Markdown.Html.oneOf (customRenderers audioPlayerConfig)


customRenderers : Maybe (AudioPlayerConfig msg) -> List (Markdown.Html.Renderer (List Doc.Intermediate -> Doc.Intermediate))
customRenderers audioPlayerConfig =
    [ View.LanguageBreak.renderer
        |> renderFailableCustom Doc.IntermediateBlock Doc.LanguageBreak
    ]


renderFailableCustom :
    (Doc.Block -> Doc.Intermediate)
    -> (a -> Doc.Block)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List b -> Doc.Intermediate)
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


renderErrorMessage : String -> Doc.Block
renderErrorMessage error =
    [ Doc.plainText "Parsing error: "
    , Doc.plainText error
    ]
        |> Doc.Paragraph



-- OTHER


unwrapInlines : List Doc.Intermediate -> List Doc.Inline
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


unwrapBlocks : List Doc.Intermediate -> List Doc.Block
unwrapBlocks =
    List.filterMap
        (\intermediate ->
            case intermediate of
                Doc.IntermediateBlock block ->
                    Just block

                _ ->
                    Nothing
        )


ensureBlocks : List Doc.Intermediate -> List Doc.Intermediate
ensureBlocks tags =
    let
        process :
            Doc.Intermediate
            -> ( List Doc.Intermediate, List Doc.Intermediate )
            -> ( List Doc.Intermediate, List Doc.Intermediate )
        process tag ( inlines, blocks ) =
            case tag of
                Doc.IntermediateInline _ ->
                    ( tag :: inlines, blocks )

                _ ->
                    ( [], tag :: wrapUpInlines ( inlines, blocks ) )

        wrapUpInlines :
            ( List Doc.Intermediate, List Doc.Intermediate )
            -> List Doc.Intermediate
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
