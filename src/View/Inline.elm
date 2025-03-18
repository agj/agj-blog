module View.Inline exposing (setCode)

import Html exposing (Html)
import Html.Attributes exposing (class)


setCode : String -> Html msg
setCode code =
    Html.span [ class "bg-layout-05 whitespace-pre-wrap rounded box-decoration-clone px-2 font-mono" ]
        [ Html.text codeString ]
