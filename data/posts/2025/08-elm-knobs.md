---
title: elm-knobs
date: "2025-08-24 15:34:00"
categories:
  - interactive
tags:
  - elm
  - web
  - release
language: eng
---

Two years ago I made [a simple Elm package](https://elm.dmy.fr/packages/agj/elm-knobs/latest/) to scratch my own itch, named `agj/elm-knobs`. I wanted a simple interface to tweak constants dynamically in order to see how they affect a visual algorithm (which was just a project I was working on for fun; I'll post about it if I actually get around to finishing it). I found a few packages that get close to what I wanted, but nothing matching precisely my needs, so I just coded the thing and eventually turned into a package.

Its intended use-case is squarely prototyping, so I didn't put effort into making it look nice or visually versatile. What I did though is add “knobs” (interactive controls) for primitive types (`Int`, `Float`, `String`, `Bool`) and a few non-primitives.

The way it works is through a `Knob a` type value, where `a` could be any type at all, as long as you have the means to create it. This knob value contains the current value of `a` and a view function that returns HTML and emits updates to itself as an event whenever the controls get manipulated. Below is a quick rundown on how to use a knob.

```elm
knob : Knob Int
knob =
    Knob.int { step = 1, initial = 0 }

knobValue : Int
knobValue =
    Knob.value knob

type Msg =
    KnobUpdated (Knob Int)

knobView : Html Msg
knobView =
    Knob.view [] KnobUpdated knob
```

Please note that _this example code and the rest of this post are actually based on unreleased v2 code;_ I guess I'll have to release that version soon, though.

And then there's ways to compose, transform and create custom knobs. You can also serialize and deserialize a knob into a string, in order to persist its value using the Web Storage API or however else you like. Some omissions I can think of are knobs for dates, and for data structures such as lists and dictionaries.

# Interactive documentation

This was my first Elm package, and I put a lot of effort into the documentation, taking it as a chance to learn and just make it as useful as possible. Elm core package documentation is way above average, so I took a lot of inspiration from it. I think that the [package docs](https://elm.dmy.fr/packages/agj/elm-knobs/1.2.0/Knob) I wrote are pretty clear and organized.

One way I tried to improve documentation was by creating [“interactive documentation”](https://agj.github.io/elm-knobs/) using [ElmBook](https://github.com/dtwrks/elm-book). It's comprised of code examples for each of the knob functions, whose resulting HTML you can see live in your browser. It's interactive in the sense that the example code shows up as interactive HTML, not in that you can tweak the code yourself, though.

One of the interesting things I did there was making sure that the example code matches what you see exactly, and that I don't have to forget to copy & paste something. Elm has no metaprogramming capabilities, so using an external tool to do this was necessary, and here comes [Comby](https://comby.dev/) to the rescue! (Think [sed](https://en.wikipedia.org/wiki/Sed), but for manipulating code syntax instead of plain text.) Take a look at the Elm code below describing some knob code example. Using [a very short script I wrote using Comby](https://github.com/agj/elm-knobs/blob/d0acf8c5a3d97ef714185e3f090bb33cda988ea1/scripts/update-example-code-strings.nu), the string value in the `code` field gets filled with what's in the `init_` field automatically. Having these two synchronized makes sure that example code is always valid, since otherwise the interactive docs would not compile either.

```elm
floatDoc : KnobDoc Float Model
floatDoc =
    { name = "float"
    , link = Nothing
    , description = Nothing
    , init_ =
        Knob.float { step = 0.01, initial = 0 }
    , code =
        """
        Knob.float { step = 0.01, initial = 0 }
        """
    , get = \model -> model.float
    , set = \model new -> { model | float = new }
    , toString = String.fromFloat
    }
```

Another thing you might notice from the code block above is that I used some tricks to make writing the documentation more DRY (i.e. more consistent, less error-prone). With ElmBook you write Markdown to define the content of each page. I generate this Markdown from records like the one you see above. [Here's the module I wrote for that purpose](https://github.com/agj/elm-knobs/blob/d0acf8c5a3d97ef714185e3f090bb33cda988ea1/interactive-docs/src/KnobDoc.elm), although it might be a bit hard to follow, especially given that it's written to accomodate the ElmBook API. But at any rate, something like the above turns into [what you see here](https://agj.github.io/elm-knobs/1.2.0/#/knob-examples/number).

I'm not happy with having to split the “API docs” and the “interactive docs”, so at some point I might figure out a way of automatically parsing the Elm comment docs and inserting it into the interactive documentation, to keep it all in one place. Sounds like a lot of effort for such a relatively useless package, so if I ever end up going through the trouble, it'll be for the learning opportunity (or maybe my OCD.)

# Property-based testing

I test all knobs using property-based tests (which in [elm-test](https://github.com/elm-explorations/test) are called “fuzzers”, although that is [the wrong term](https://en.wikipedia.org/wiki/Fuzzing)). The idea is that instead of each test checking for one or a few input values against an expected result, we test a whole range of them, so we can make sure that our function behaves the way we expect. This technique receives this name because we can't use the same strategy for standard unit tests and check the return value by equality; we need to instead test that a given property holds.

For instance, I have a suite of serialization tests. I have two types

- Something I called “transitive equality”, for lack of a better term: If two knobs correspond to the same value, the result of serializing them should also be equal, and vice-versa.
- A classic [round-trip test](https://fsharpforfunandprofit.com/posts/property-based-testing-3/#inverseRev): We serialize and then deserialize a, and expect the value of the input knob and of the result to be identical.

- Testing tricks, property-based.
- More about ElmBook.
- Version and other checks.
