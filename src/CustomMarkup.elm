module CustomMarkup exposing (toElmUi)

import Custom.Color as Color
import CustomMarkup.ElmUiTag as ElmUiTag exposing (ElmUiTag)
import Element as Ui
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
        |> Ui.column []



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
    { blockQuote = \tags -> Ui.row [] (getInlines tags) |> ElmUiTag.Block
    , codeBlock = \{ body, language } -> Ui.text body |> ElmUiTag.Block
    , codeSpan = \code -> Ui.text code |> ElmUiTag.Inline
    , emphasis = renderInlineWithStyle UiFont.italic
    , hardLineBreak = Ui.text "\n" |> ElmUiTag.Block
    , heading = renderHeading
    , html = Markdown.Html.oneOf (otherCustomRenderers ++ audioPlayerRenderers)
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
            Ui.paragraph
                (baseBlockStyles
                    ++ [ Ui.paddingXY 0 Style.spacing.size3
                       ]
                )
                (getInlines tags)
                |> ElmUiTag.Block


baseBlockStyles : List (Ui.Attribute msg)
baseBlockStyles =
    [ Ui.paddingXY 0 10
    , UiFont.color (Color.toElmUi Style.color.layout)
    , UiFont.size Style.textSize.m
    , Ui.spacing (Style.interline.m Style.textSize.m)
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
