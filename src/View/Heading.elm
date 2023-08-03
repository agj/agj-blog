module View.Heading exposing (..)

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Font as UiFont
import Element.Region as UiRegion
import Style


view : Int -> List (Ui.Element msg) -> Ui.Element msg
view level content =
    let
        normalizedLevel =
            max 1 level

        basePadding =
            Style.blockPadding fontSize Style.interline.s

        baseStyles =
            [ UiFont.color (Color.toElmUi Style.color.layout)
            , UiFont.size fontSize
            , Ui.spacing (Style.interline.s fontSize)
            , Ui.width Ui.fill
            , UiRegion.heading normalizedLevel
            , Ui.paddingEach
                { top = basePadding + Style.spacing.size5
                , bottom = basePadding
                , left = 0
                , right = 0
                }
            ]

        ( fontSize, styles, prepend ) =
            case normalizedLevel of
                1 ->
                    ( Style.textSize.xxl
                    , [ UiFont.bold ]
                    , Nothing
                    )

                2 ->
                    ( Style.textSize.xl
                    , [ UiFont.bold ]
                    , Nothing
                    )

                3 ->
                    ( Style.textSize.l
                    , [ UiFont.bold ]
                    , Nothing
                    )

                4 ->
                    ( Style.textSize.l
                    , []
                    , Nothing
                    )

                _ ->
                    ( Style.textSize.l
                    , []
                    , Just (String.repeat (normalizedLevel - 3) "▹")
                    )

        prependEl =
            case prepend of
                Just text ->
                    Ui.text (text ++ " ")
                        |> Ui.el
                            [ Ui.hiddenToScreenReaders
                            , Ui.nonSelectable
                            ]

                Nothing ->
                    Ui.text ""
    in
    Ui.paragraph (baseStyles ++ styles)
        (prependEl :: content)
