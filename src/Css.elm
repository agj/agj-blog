module Css exposing (..)


type Expression
    = Unitless Float
    | Pixels Float
    | Ems Float
    | Var String
    | CalcAddition Expression Expression
    | CalcSubtraction Expression Expression
    | CalcMultiplication Expression Expression


expressionToString : Expression -> String
expressionToString expression =
    case expression of
        Unitless num ->
            String.fromFloat num

        Pixels num ->
            String.fromFloat num ++ "px"

        Ems num ->
            String.fromFloat num ++ "em"

        Var var ->
            "var(--{var})"
                |> String.replace "{var}" var

        CalcAddition left right ->
            "calc({left} + {right})"
                |> String.replace "{left}" (expressionToString left)
                |> String.replace "{right}" (expressionToString right)

        CalcSubtraction left right ->
            "calc({left} - {right})"
                |> String.replace "{left}" (expressionToString left)
                |> String.replace "{right}" (expressionToString right)

        CalcMultiplication left right ->
            "calc({left} * {right})"
                |> String.replace "{left}" (expressionToString left)
                |> String.replace "{right}" (expressionToString right)
