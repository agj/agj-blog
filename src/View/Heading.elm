module View.Heading exposing (..)

import Custom.Color as Color
import Element as Ui
import Element.Font as UiFont
import Element.Region as UiRegion
import Html.Attributes
import Style


type Heading msg
    = Heading
        { content : List (Ui.Element msg)
        , level : Int
        }


fromContent : Int -> List (Ui.Element msg) -> Heading msg
fromContent level content =
    Heading
        { content = content
        , level = level
        }


view : Heading msg -> Ui.Element msg
view (Heading { content, level }) =
    let
        basePadding =
            Style.blockPadding fontSize Style.interline.s

        baseStyles =
            [ UiFont.color (Color.toElmUi Style.color.layout)
            , UiFont.size fontSize
            , Ui.spacing (Style.interline.s fontSize)
            , Ui.width Ui.fill
            , UiRegion.heading level
            , Ui.paddingEach
                { top = basePadding + Style.spacing.size5
                , bottom = basePadding
                , left = 0
                , right = 0
                }
            ]

        ( fontSize, styles, prepend ) =
            case level of
                1 ->
                    ( Style.textSize.xl
                    , [ UiFont.bold ]
                    , Nothing
                    )

                2 ->
                    ( Style.textSize.l
                    , [ UiFont.bold ]
                    , Nothing
                    )

                3 ->
                    ( Style.textSize.l
                    , []
                    , Nothing
                    )

                _ ->
                    ( Style.textSize.l
                    , []
                    , Just (String.repeat (level - 3) "▹")
                    )

        prependEl =
            case prepend of
                Just text ->
                    Ui.text (text ++ " ")
                        |> Ui.el
                            [ Html.Attributes.attribute "aria-hidden" "true"
                                |> Ui.htmlAttribute
                            , Html.Attributes.style "user-select" "none"
                                |> Ui.htmlAttribute
                            ]

                Nothing ->
                    Ui.text ""
    in
    Ui.paragraph (baseStyles ++ styles)
        (prependEl :: content)
