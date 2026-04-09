---
title: Traditional Chinese characters’ study order
date: "2026-04-09 17:29:00"
categories:
  - language
  - interactive
tags:
  - language
  - learning
  - chinese
  - javascript
language: eng
---

Again posting about something old. This little project: [“3000+ traditional hanzi Anki deck.”](https://github.com/agj/3000-traditional-hanzi) That links to the Github project; the readme file has a lot of information, but in this post I'll expound on it a bit more, including its most recent developments.

I started it in 2017, as I began learning Mandarin Chinese. One of the big tasks was learning a good bunch of Chinese characters. Having learned Japanese previously, I already knew how to approach this: [the James Heisig method](https://en.wikipedia.org/wiki/Remembering_the_Kanji).

His book teaches you to memorize the meaning of each character by starting with more elemental ones such as 人 (person) and 匕 (ladle), and later using that knowledge to help you memorize the meaning of compound characters, such as 化 (change). And while there is a more recent version of his book targeting Chinese, I had already gone through the process and basically only needed a list of the most useful (frequently used) characters, ordered by their decomposition.

Another wrinkle in this process is that I was learning [traditional characters](https://en.wikipedia.org/wiki/Traditional_Chinese_characters), while most study material you find out there targets the more hegemonic simplified characters used in mainland China. The reasons for my choice include the fact that I wanted to learn something closer to the historic etymology of the characters. The traditional design of Chinese writing can be seen in old Japanese books and signage, predating the modern stylistic standardization that took place within the education system; as well as, of course, in China predating the simplification reform.

Traditional characters are a bit of a time capsule for Chinese writing, and they _just look cool._ Tell me which one is the most dragon-like here: the simplified 龙 or the traditional 龍.

Anyway, I went ahead and gathered different sources for traditional characters, their use frequency, decomposition information, and other details. Then I devised a bit of code that collates all of that and pops out a “tab-separated values” file on the other end, which is something easy to import into the flashcards software I used, [Anki](https://apps.ankiweb.net/). The important part was generating a study order that went from most basic and built up to complex, while also maintaining use frequency in consideration, so as not to waste much time starting with comparatively rare characters.

I filled the columns for each character with various useful bits of information, such as: vocabulary that includes the character; simplified version of the character; pronunciation in [pinyin](https://en.wikipedia.org/wiki/Pinyin), [zhuyin](https://en.wikipedia.org/wiki/Bopomofo) (prompted by a user who wanted it) and Japanese; code for typing the character using [Cangjie input](https://en.wikipedia.org/wiki/Cangjie_input_method); and more.

Another thing is that I initially wrote the code in JavaScript, and frankly it wasn't very maintainable. The code, while not quite spaghetti, performed a lot of data transformations in a pipeline-style using my library [dot-into](https://blog.agj.cl/tag/?t=dot-into). With no type information to keep track of what is what at any which point, it was hard to debug and extend. Just for future maintainability, I thoroughly commented all functions and migrated all that code to TypeScript, to at least have those types in order, add some static analysis to keep things in check.

In that process I migrated from [Ramda](https://ramdajs.com/) to [Remeda](https://remedajs.com/), two equivalent functional utility libraries whose main distinction is that Remeda is TypeScript-native. While I really appreciate Ramda, working with it in TypeScript is not a very pleasant experience. I ran into lots of problems due to inadequate typing, since the library was built to be very dynamic. On the other hand, Remeda's types are excellent.

I also updated dependencies, and actually got rid of a few unnecessary npm packages. And in updating one such package, some errors in the output data got fixed. I didn't even realize that some data in the zhuyin column was wrong.

Oh, I also updated the project structure to use [my standard setup with Nix and Just](https://blog.agj.cl/2025/08/como-uso-nix-nushell-y-just-para-configurar-mis-proyectos-de-codigo), which I find pleasant to use and is hopefully more future-proof!
