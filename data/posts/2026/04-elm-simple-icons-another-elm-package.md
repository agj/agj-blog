---
title: "elm-simple-icons: Another Elm package"
date: "2026-04-14 21:28:00"
categories:
  - interactive
tags:
  - elm-simple-icons
  - elm
  - release
  - nushell
  - library
language: eng
---

I released a new Elm package: [agj/**elm-simple-icons**](https://package.elm-lang.org/packages/agj/elm-simple-icons/latest/), an Elm conversion of a project called [Simple Icons](https://simpleicons.org/). It's a collection of icon versions of many logos for brands and projects. This is a practical tool to have lying around to, say, put a little Wikipedia icon next to a link pointing to a Wikipedia article, or otherwise visually annotate content related to external services. I sent a PR to the Simple Icons project to add my package to their list of “third party extensions,” and it's already listed [on their website](https://simpleicons.org/?modal=extensions) next to many other similar packages.

Frankly, the project lies in a bit of a legal gray area, since these logos are their respective owners' copyright and whatnot. The Simple Icons project tries to deflect this problem by offering a [legal disclaimer](https://github.com/simple-icons/simple-icons/blob/develop/DISCLAIMER.md). Some brands are not included precisely because their owners have opted out. So it has a bit of that “piracy vibe” to it, although this being just branding material it's nothing very serious. This is only use of visual material that these brands have chosen to be their public face. Now, on my side I've also linked to their disclaimer, and I made sure to put license and branding information in the documentation for each icon in the package, for those cases in which it's available (admittedly not many).

My package, being a repackaging of the Simple Icons SVGs, is automatically generated from that source data. I briefly considered using [elm-codegen](https://github.com/mdgriffith/elm-codegen) for that task, but I concluded that while it would be a great solution for generating the Elm code itself, it would be less ideal for the data munging part of it—I'd probably need to pass data in and out of Elm more than I would like. Also, the setup complexity cost was higher.

So I used Nushell for the code generation. It was actually really easy; [the script](https://github.com/agj/elm-simple-icons/blob/be5f40082f9a13398593d103b9ab0f23cbccfb3c/scripts/build.nu) is under 300 lines. It just reads the SVG data and converts it into Elm syntax, which is made simple thanks to Nushell's support for parsing XML data. Another big part of the script is generating the documentation, which is also simple since the source package includes a big JSON metadata file; I just need to surface that information.

For the user-facing API I researched Elm icon libraries, and ended up loosely basing mine on the [Phosphor icons package](https://package.elm-lang.org/packages/phosphor-icons/phosphor-elm/latest/) solution. My package is not a traditional icons library, as each icon has its own brand color associated to it, and they also have a `<title>` element with the brand name, which shows up as a mouse hover “tooltip” on browsers. So those two things, plus the icon size, were what I allow to configure via a [“builder pattern”](https://sporto.github.io/elm-patterns/basic/builder-pattern.html) interface of `with*` functions, ending in a `toHtml` function that takes an optional list of HTML attributes. So far, so good.

```elm
SimpleIcons.elm
    |> SimpleIcons.withColor "#FF00FF"
    |> SimpleIcons.withSize "50px"
    |> SimpleIcons.withNoTitle
    |> SimpleIcons.toHtml [ Html.Attributes.class "icon" ]
```

It's still a work in progress, but I'm also coding up a Nushell script to make it easier to keep my package up-to-date with the source package. It uses [npm-check-updates](https://github.com/raineorshine/npm-check-updates) to update the version in `package.json`, regenerates stuff, then tries to update version numbers all around. I'm trying to get it to also update the changelog with added and removed icon names. Might I even put this all in a Github Action, to fully automate the process? Not likely, since I don't trust the automation enough to let it publish a package on my behalf. Maybe to generate a PR, but eh, most likely not worth the trouble.

I also put good effort into making sure that the code and the documentation are solid. For one, I added tests for each configuration function that run on each icon. I didn't go full property-based testing [like I did on elm-knobs](https://blog.agj.cl/2025/08/on-my-elm-knobs-elm-package), since I'm only basically just checking that each function did modify the SVG in the place it's supposed to.

I also used a great elm-review rule: [lue-bird/elm-review-documentation-code-snippet](https://package.elm-lang.org/packages/lue-bird/elm-review-documentation-code-snippet/latest/). What I use it for is a basic sanity check of all code snippets in the docs. If you take a look at [my package docs](https://package.elm-lang.org/packages/agj/elm-simple-icons/1.1.0/SimpleIcons), you'll see that all example code ends with a comment like: `--: SimpleIcons.Icon`. This instructs the elm-review rule to check that the preceding bit of code resolves to the stated type. And while checking the type is cool, I'm already happy enough that it will attempt to compile the code at all, as that would be the first likely problem to occur if the API changed and the examples were to get outdated.

One little trick I learned from Dillon Kearn's [Idiomatic Elm Package Guide](https://github.com/dillonkearns/idiomatic-elm-package-guide), and which I put into practice in this package, is that I can use `elm make --docs=file.json` to confirm that the package documentation satisfies the Elm package repository requirements early. What it does is attempt to generate a JSON file that contains all the package documentation, but it will fail if there's missing docs for exported members, if something's incorrectly formatted, etc. So that line is one of the commands that my `check` task runs, in addition to attempting compilation, running tests, and running elm-review.

This was the second Elm package I release. I think I'm getting the hang of it. Hopefully it'll be helpful to someone other than me, eventually!
