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
import Review.Rule exposing (Rule)
import TailwindCss.ClassOrder exposing (classOrder)
import TailwindCss.ConsistentClassOrder
import TailwindCss.NoCssConflict
import TailwindCss.NoUnknownClasses


config : List Rule
config =
    [ TailwindCss.ConsistentClassOrder.rule (TailwindCss.ConsistentClassOrder.defaultOptions { order = TailwindCss.ClassOrder.classOrder })
    , TailwindCss.NoCssConflict.rule (TailwindCss.NoCssConflict.defaultOptions { props = TailwindCss.ClassOrder.classProps })
    , TailwindCss.NoUnknownClasses.rule (TailwindCss.NoUnknownClasses.defaultOptions { order = classOrder })
    -- , NoUnused.CustomTypeConstructors.rule []
    -- , NoUnused.CustomTypeConstructorArgs.rule
    -- , NoUnused.Dependencies.rule
    -- , NoUnused.Exports.rule
    -- , NoUnused.Parameters.rule
    -- , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    ]
