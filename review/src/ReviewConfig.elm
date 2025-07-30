module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import TailwindCss.ClassOrder exposing (classOrder)
import TailwindCss.ConsistentClassOrder
import TailwindCss.NoUnknownClasses


config : List Rule
config =
    [ TailwindCss.ConsistentClassOrder.rule (TailwindCss.ConsistentClassOrder.defaultOptions { order = TailwindCss.ClassOrder.classOrder })
    , TailwindCss.NoUnknownClasses.rule (TailwindCss.NoUnknownClasses.defaultOptions { order = classOrder })
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForDirectories [ "app" ]
        |> Rule.ignoreErrorsForFiles [ "src/Icon.elm" ]
    , NoUnused.Variables.rule

    -- , TailwindCss.NoCssConflict.rule (TailwindCss.NoCssConflict.defaultOptions { props = TailwindCss.ClassOrder.classProps })
    -- , NoUnused.Parameters.rule
    -- , NoUnused.Dependencies.rule
    -- , NoUnused.Patterns.rule
    ]
