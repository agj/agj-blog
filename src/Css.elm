module Css exposing (..)


type Expression
    = Var String


expressionToString : Expression -> String
expressionToString expression =
    case expression of
        Var var ->
            "var(--{var})"
                |> String.replace "{var}" var
