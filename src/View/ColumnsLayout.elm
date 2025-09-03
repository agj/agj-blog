module View.ColumnsLayout exposing (view2)

import Html exposing (Html)
import Html.Attributes exposing (class)


view2 : { main : Html msg, side : Html msg } -> Html msg
view2 { main, side } =
    Html.div
        [ class "grid gap-6"
        , class "md:grid-cols-[2fr_1fr]"
        ]
        [ Html.main_ [] [ main ]
        , Html.aside [ class "order-first md:order-last" ] [ side ]
        ]
