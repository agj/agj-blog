module Doc exposing (..)

import View.AudioPlayer.Track exposing (Track)


type Inline
    = Text StyledText
    | InlineCode String
    | Link { target : String, inlines : List StyledText }


type Block
    = Paragraph (List Inline)
    | Section { heading : List Inline, content : List Block }
    | List Block (List Block)
    | BlockQuote (List Block)
    | CodeBlock String
    | Image { url : String, description : String }
    | Separation
    | Video
    | AudioPlayer


type alias StyledText =
    { text : String, styles : Styles }


type alias Styles =
    { bold : Bool
    , italic : Bool
    , strikethrough : Bool
    }


type Intermediate
    = IntermediateBlock Block
    | IntermediateInline Inline
    | IntermediateInlineList (List Inline)
    | IntermediateCustom Metadata


type Metadata
    = AudioPlayerTrack Track


plainText : String -> Inline
plainText text =
    Text { text = text, styles = emptyStyles }


link : String -> List StyledText -> Inline
link target inlines =
    Link { target = target, inlines = inlines }


inlineCode : String -> Inline
inlineCode text =
    InlineCode text


setBold : Inline -> Inline
setBold =
    mapStyles (\styles -> { styles | bold = True })


setItalic : Inline -> Inline
setItalic =
    mapStyles (\styles -> { styles | italic = True })


setStrikethrough : Inline -> Inline
setStrikethrough =
    mapStyles (\styles -> { styles | strikethrough = True })


toLink : String -> List Inline -> Inline
toLink target inlines =
    let
        styledTexts =
            inlines
                |> List.filterMap
                    (\inline ->
                        case inline of
                            Text styledText ->
                                Just [ styledText ]

                            Link l ->
                                Just l.inlines

                            InlineCode text ->
                                Just [ { text = text, styles = emptyStyles } ]
                    )
                |> List.concat
    in
    Link { target = target, inlines = styledTexts }


mapStyles : (Styles -> Styles) -> Inline -> Inline
mapStyles mapper inline =
    case inline of
        Text styledText ->
            Text (mapStyledTextStyles mapper styledText)

        Link ({ inlines } as config) ->
            Link { config | inlines = inlines |> List.map (mapStyledTextStyles mapper) }

        InlineCode _ ->
            inline


mapStyledTextStyles : (Styles -> Styles) -> StyledText -> StyledText
mapStyledTextStyles mapper styledText =
    { styledText | styles = mapper styledText.styles }


emptyStyles : Styles
emptyStyles =
    { bold = False
    , italic = False
    , strikethrough = False
    }
