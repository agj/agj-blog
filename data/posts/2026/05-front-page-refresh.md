---
title: Front page refresh
date: "2026-05-10 00:42:00"
categories:
  - interactive
tags:
  - front-page-design
  - gleam
  - archive
  - web
  - graphic-design
language: eng
external:
  mastodon-toot-id: "116547512261531415"
---

I remade the front page for [agj.cl](https://agj.cl). This time I developed it using [Gleam](https://gleam.run/), since it's been an objective of mine these past few months to get better acquainted with the language. It's not any different from what I would've done had I stuck with [Elm](https://elm-lang.org/), because [Lustre](https://hexdocs.pm/lustre) (the UI library) uses almost the exact same architecture.

Here's what it looks like at this moment:

![screenshot](/files/2026/05-front-page-refresh/new-front-page.png "New front page.")

I wasn't so fond of the previous design by now, and I tried to replace it with something simple, elegant and with some character to it—though you might disagree with me on some of these points. I'm sure it won't survive exactly like this for too long. I want to eventually play a bit with the colors and animating the background pattern. For now though, my priority was to get something basic out the door.

By the way, [the code is up on Github](https://github.com/agj/agj-front/tree/da9ebfc81e491a443d0846b8094badb2e439c8f2), if you want to check it out (the link points to the commit current at the time of posting.)

I'm quite fond of the animation when opening the language selection menu! It's a diagonal sweep using a linear gradient as a [CSS mask](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/mask). It took me a while getting it to work right cross-browser. I ended up using CSS animations and more event-listening ([`animationend`](https://developer.mozilla.org/en-US/docs/Web/API/Element/animationend_event)) than I'd like. But the result is not too messy. Here's [the relevant CSS portion](https://github.com/agj/agj-front/blob/da9ebfc81e491a443d0846b8094badb2e439c8f2/src/main.css#L152-L185). In the Gleam code the [`OpenState` type](https://github.com/agj/agj-front/blob/da9ebfc81e491a443d0846b8094badb2e439c8f2/src/app.gleam#L50) defines open, closed and “closing” states for the language menu, the latter of which triggers the closing animation, after which the menu element gets removed from the DOM.

![screenshot](/files/2026/05-front-page-refresh/language-menu-animation.png "Two frames of the language selection menu getting opened.")

I did spend some time making the menu accessible, by using the proper ARIA roles and implementing appropriate keyboard navigation. That latter part did make the code a lot more effectful than I'd like, since it involves manipulating element focus.

I had a lot of trouble making the content blocks perfectly line up with the tiled background, and I'm sure that there's still a lot of browser and device combinations that won't display it how it's supposed to; oh well. I make things line up by giving the background image a size of 1 rem in both width and height, and using integer rem units to set the size and position of each content block in the page. Later, when (and if) I attempt animating that background, I'll need to take a different approach, though.

Below is how the page used to look. The Elm code for that version remains archived in the [repository on Github](https://github.com/agj/agj-front/tree/v2-elm).

![screenshot](/files/2026/05-front-page-refresh/previous-front-page.png "Previous version of the page.")
