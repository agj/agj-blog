module View.Paragraph exposing (view)

import Html exposing (Html)
import Html.Attributes exposing (class)


view : List (Html msg) -> Html msg
view inlines =
    Html.p [ class "w-full py-2 text-base" ]
        inlines
