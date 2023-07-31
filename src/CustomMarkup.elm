module CustomMarkup exposing (toElmUi)

import Custom.Color as Color
import CustomMarkup.ElmUiTag as ElmUiTag exposing (ElmUiTag)
import Element as Ui
import Element.Background as UiBackground
import Element.Font as UiFont
import Element.Region as UiRegion
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
import View.Figure
import View.LanguageBreak
import View.VideoEmbed


type alias Config msg =
    { audioPlayer :
        Maybe
            { audioPlayerState : View.AudioPlayer.State
            , onAudioPlayerStateUpdated : View.AudioPlayer.State -> msg
            }
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
        |> wrapElmUiBlocks



-- INTERNAL


renderer : Config msg -> Markdown.Renderer.Renderer (ElmUiTag msg)
renderer config =
    let
        audioPlayerRenderers =
            case config.audioPlayer of
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
    { -- Inline
      text = \text -> Ui.text text |> ElmUiTag.Inline
    , strong = renderInlineWithStyle UiFont.bold
    , emphasis = renderInlineWithStyle UiFont.italic
    , strikethrough = renderInlineWithStyle UiFont.strike
    , link = renderLink
    , codeSpan = \code -> Ui.text code |> ElmUiTag.Inline

    -- Block
    , paragraph = renderParagraph
    , heading = renderHeading
    , unorderedList = renderUnorderedList
    , orderedList = renderOrderedList
    , blockQuote = renderBlockQuote
    , codeBlock = \{ body, language } -> Ui.text body |> ElmUiTag.Block

    -- Special
    , hardLineBreak = Ui.text "\n" |> ElmUiTag.Block
    , image =
        \{ alt, src, title } ->
            Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
                |> ElmUiTag.Block
    , thematicBreak = Ui.text "---" |> ElmUiTag.Block
    , html = Markdown.Html.oneOf (otherCustomRenderers ++ audioPlayerRenderers)

    -- Table
    , table =
        \tags ->
            Ui.column [] (getInlines tags)
                |> ElmUiTag.Block
    , tableBody = \tags -> Ui.column [] (getInlines tags) |> ElmUiTag.Block
    , tableCell = \mAlignment tags -> Ui.paragraph [] (getInlines tags) |> ElmUiTag.Block
    , tableHeader = \tags -> Ui.column [] (getInlines tags) |> ElmUiTag.Block
    , tableHeaderCell = \mAlignment tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    , tableRow = \tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    }


renderInlineWithStyle : Ui.Attribute msg -> List (ElmUiTag msg) -> ElmUiTag msg
renderInlineWithStyle attr tags =
    Ui.paragraph [ attr ] (getInlines tags)
        |> ElmUiTag.Inline


renderLink : { title : Maybe String, destination : String } -> List (ElmUiTag msg) -> ElmUiTag msg
renderLink { title, destination } tags =
    Ui.link []
        { url = destination
        , label =
            Ui.paragraph
                [ UiFont.underline
                , UiFont.color (Style.color.secondary70 |> Color.toElmUi)
                ]
                (getInlines tags)
        }
        |> ElmUiTag.Inline


renderParagraph : List (ElmUiTag msg) -> ElmUiTag msg
renderParagraph tags =
    let
        styles =
            baseBlockStyles
                ++ [ Ui.paddingXY 0 (Style.blockPadding Style.textSize.m Style.interline.m) ]
    in
    tags
        |> getInlines
        |> Ui.paragraph styles
        |> ElmUiTag.Block


renderOrderedList : Int -> List (List (ElmUiTag msg)) -> ElmUiTag msg
renderOrderedList startNumber items =
    items
        |> List.indexedMap (\index item -> renderOrderedListItem (index + startNumber) item)
        |> wrapElmUiBlocksWithoutSpacing
        |> ElmUiTag.Block


renderOrderedListItem : Int -> List (ElmUiTag msg) -> Ui.Element msg
renderOrderedListItem num tags =
    let
        styles =
            baseBlockStyles
                ++ [ Ui.paddingXY 0 (Style.blockPadding Style.textSize.m Style.interline.m)
                   , Ui.alignTop
                   ]

        number =
            Ui.paragraph
                (styles ++ [ Ui.width (Ui.px Style.spacing.size6) ])
                [ Ui.text (String.fromInt num ++ ".") ]

        addNumber content =
            Ui.row [ Ui.width Ui.fill ]
                [ number
                , content
                ]
    in
    tags
        |> ensureBlocks
        |> getBlocks
        |> wrapElmUiBlocksWithoutSpacing
        |> addNumber


renderUnorderedList : List (Markdown.Block.ListItem (ElmUiTag msg)) -> ElmUiTag msg
renderUnorderedList items =
    items
        |> List.map renderUnorderedListItem
        |> wrapElmUiBlocksWithoutSpacing
        |> ElmUiTag.Block


renderUnorderedListItem : Markdown.Block.ListItem (ElmUiTag msg) -> Ui.Element msg
renderUnorderedListItem (Markdown.Block.ListItem task tags) =
    let
        styles =
            baseBlockStyles
                ++ [ Ui.paddingXY 0 (Style.blockPadding Style.textSize.m Style.interline.m)
                   , Ui.alignTop
                   ]

        bullet =
            Ui.paragraph
                (styles ++ [ Ui.width (Ui.px Style.spacing.size6) ])
                [ Ui.text "•" ]

        addBullet content =
            Ui.row [ Ui.width Ui.fill ]
                [ bullet
                , content
                ]
    in
    tags
        |> ensureBlocks
        |> getBlocks
        |> wrapElmUiBlocksWithoutSpacing
        |> addBullet


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
        |> getBlocks
        |> wrapElmUiBlocks
        |> toQuote
        |> ElmUiTag.Block


baseBlockStyles : List (Ui.Attribute msg)
baseBlockStyles =
    [ UiFont.color (Color.toElmUi Style.color.layout)
    , UiFont.size Style.textSize.m
    , Ui.spacing (Style.interline.m Style.textSize.m)
    , Ui.width Ui.fill
    ]


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (ElmUiTag msg)
    }
    -> ElmUiTag msg
renderHeading { level, children } =
    let
        styles =
            case level of
                Markdown.Block.H1 ->
                    [ UiFont.size Style.textSize.xxl ]

                Markdown.Block.H2 ->
                    [ UiFont.size Style.textSize.xl
                    , Ui.htmlAttribute (Html.Attributes.style "text-transform" "uppercase")
                    ]

                Markdown.Block.H3 ->
                    [ UiFont.size Style.textSize.xl ]

                Markdown.Block.H4 ->
                    [ UiFont.size Style.textSize.l
                    , Ui.htmlAttribute (Html.Attributes.style "text-transform" "uppercase")
                    ]

                Markdown.Block.H5 ->
                    [ UiFont.size Style.textSize.l ]

                Markdown.Block.H6 ->
                    [ UiFont.size Style.textSize.m
                    , UiFont.bold
                    ]
    in
    Ui.paragraph
        (baseBlockStyles
            ++ [ UiRegion.heading (Markdown.Block.headingLevelToInt level)
               , Ui.paddingEach
                    { top = Style.spacing.size4
                    , bottom = Style.spacing.size3
                    , left = 0
                    , right = 0
                    }
               ]
            ++ styles
        )
        (getInlines children)
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


wrapBlocks : List (ElmUiTag msg) -> ElmUiTag msg
wrapBlocks tags =
    tags
        |> ensureBlocks
        |> getBlocks
        |> wrapElmUiBlocks
        |> ElmUiTag.Block


wrapElmUiBlocks : List (Ui.Element msg) -> Ui.Element msg
wrapElmUiBlocks els =
    Ui.column
        [ Ui.spacing Style.spacing.size3
        , Ui.width Ui.fill
        ]
        els


wrapElmUiBlocksWithoutSpacing : List (Ui.Element msg) -> Ui.Element msg
wrapElmUiBlocksWithoutSpacing els =
    Ui.column
        [ Ui.width Ui.fill ]
        els


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
