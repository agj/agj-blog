module Custom.Html.Attributes exposing (customProperties, none)

import Html exposing (Attribute)
import Html.Attributes


none : Attribute msg
none =
    Html.Attributes.classList []


{-| Define a list of CSS custom properties (otherwise known as variables, those
starting with `--`) and their values as an attribute to set to an element. It
and its children will have these properties set as defined.
-}
customProperties : List ( String, String ) -> Attribute msg
customProperties propertyNameValuePairs =
    propertyNameValuePairs
        |> List.map (\( name, value ) -> "--" ++ name ++ ": " ++ value)
        |> String.join "; "
        |> Html.Attributes.attribute "style"
