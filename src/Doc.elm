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
    | Image String
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
    | IntermediateCustom Metadata


type Metadata
    = AudioPlayerTrack Track


plainText : String -> Inline
plainText text =
    Text { text = text, styles = emptyStyles }


setBold : Inline -> Inline
setBold =
    mapStyles (\styles -> { styles | bold = True })


setItalic : Inline -> Inline
setItalic =
    mapStyles (\styles -> { styles | italic = True })


setStrikethrough : Inline -> Inline
setStrikethrough =
    mapStyles (\styles -> { styles | strikethrough = True })


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
