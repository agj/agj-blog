module View.Inline exposing (code)

import Html exposing (Html)
import Html.Attributes exposing (class)


code : String -> Html msg
code codeString =
    Html.span [ class "bg-layout-05 whitespace-pre-wrap rounded box-decoration-clone px-2 font-mono" ]
        [ Html.text codeString ]
