module Data.PageHeader exposing (..)

import Element as Ui
import View.Column exposing (Spacing(..))
import View.Heading


view : List (Ui.Element msg) -> Maybe (Ui.Element msg) -> Ui.Element msg
view title subtitleM =
    case subtitleM of
        Just subtitle ->
            [ View.Heading.view 1 title
            , subtitle
            ]
                |> View.Column.setSpaced MSpacing

        Nothing ->
            View.Heading.view 1 title
