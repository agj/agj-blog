module Custom.Html.Attributes exposing (customProperties)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)


customProperties : List ( String, String ) -> Attribute msg
customProperties =
    List.map (\( name, value ) -> "--" ++ name ++ ": " ++ value)
        >> String.join "; "
        >> attribute "style"
