module Doc.Markdown exposing
    ( AudioPlayerConfig
    , Config
    , parse
    )

import Doc
import List.Extra as List
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import View.AudioPlayer
import View.AudioPlayer.Track exposing (Track)
import View.Column exposing (Spacing(..))


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
    , strong = renderInlineWithStyleDoc Doc.setBold
    , emphasis = renderInlineWithStyleDoc Doc.setItalic
    , strikethrough = renderInlineWithStyleDoc Doc.setStrikethrough
    , link = renderDocLink
    , codeSpan = renderDocInlineCode

    -- Block
    , paragraph = renderDocParagraph
    , heading = \_ -> placeholderDoc
    , unorderedList = \_ -> placeholderDoc
    , orderedList = \_ _ -> placeholderDoc
    , blockQuote = \_ -> placeholderDoc
    , codeBlock = \_ -> placeholderDoc

    -- Special
    , hardLineBreak = placeholderDoc
    , image = renderDocImage
    , thematicBreak = placeholderDoc
    , html = Markdown.Html.oneOf []

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


renderInlineWithStyleDoc : (Doc.Inline -> Doc.Inline) -> List Doc.Intermediate -> Doc.Intermediate
renderInlineWithStyleDoc styler intermediates =
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


renderDocLink : { title : Maybe String, destination : String } -> List Doc.Intermediate -> Doc.Intermediate
renderDocLink { destination } intermediates =
    intermediates
        |> unwrapDocInlines
        |> Doc.toLink destination
        |> Doc.IntermediateInline


renderDocInlineCode : String -> Doc.Intermediate
renderDocInlineCode code =
    Doc.inlineCode code
        |> Doc.IntermediateInline


renderDocParagraph : List Doc.Intermediate -> Doc.Intermediate
renderDocParagraph intermediates =
    case intermediates of
        (Doc.IntermediateBlock block) :: _ ->
            -- Images get put into paragraphs.
            Doc.IntermediateBlock block

        _ ->
            intermediates
                |> unwrapDocInlines
                |> Doc.Paragraph
                |> Doc.IntermediateBlock


renderDocImage : { alt : String, src : String, title : Maybe String } -> Doc.Intermediate
renderDocImage { alt, src, title } =
    Doc.Image { url = src, description = alt }
        |> Doc.IntermediateBlock


unwrapDocInlines : List Doc.Intermediate -> List Doc.Inline
unwrapDocInlines intermediates =
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


unwrapDocBlocks : List Doc.Intermediate -> List Doc.Block
unwrapDocBlocks =
    List.filterMap
        (\intermediate ->
            case intermediate of
                Doc.IntermediateBlock block ->
                    Just block

                _ ->
                    Nothing
        )
