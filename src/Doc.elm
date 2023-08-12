module Doc exposing (..)

import View.AudioPlayer.Track exposing (Track)


type Inline
    = Text { text : String, styles : Styles }
    | InlineCode String
    | Link { target : String, text : String, styles : Styles }


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
        Text ({ styles } as config) ->
            Text { config | styles = mapper styles }

        Link ({ styles } as config) ->
            Link { config | styles = mapper styles }

        InlineCode _ ->
            inline


emptyStyles : Styles
emptyStyles =
    { bold = False
    , italic = False
    , strikethrough = False
    }
