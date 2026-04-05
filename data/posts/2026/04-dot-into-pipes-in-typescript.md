---
title: dot-into, pipes in TypeScript
date: "2026-04-03 02:48:00"
categories:
  - interactive
tags:
  - dot-into
  - library
  - javascript
language: eng
external:
  mastodon-toot-id: "116338519658474885"
  devto-slug: "dot-into-pipes-in-typescript-1cn"
---

So I have a little library for JavaScript and TypeScript called [dot-into](https://github.com/agj/dot-into), which is something I actually every so often use in personal projects I've written using said languages. [I've posted about it before](https://blog.agj.cl/tag/?t=dot-into) back when I launched it, and I've updated it a few times. Here's the short of it:

```js
// This:
third(second(first(data)), moreData);

// Becomes this:
first(data).into(second).into(third, moreData);
```

I just released [version 3.0.0](https://github.com/agj/dot-into/tree/v3.0.0), which breaks ES5 compatibility but fixes some outstanding type inference problems that have existed since I introduced TypeScript support. Basically, it should now work with functions that use generic types. However, it's still broken for functions with multiple type signatures, sadly. But it's an easy fix:

```ts
// This breaks inference:
data.into(multiSignatureFn);

// This doesn't:
data.into((value) => multiSignatureFn(value));
```

I guess I wanted to post about it again because the biggest problem that it had, in my eyes, was that any `null` or `undefined` value in the middle of a pipe would cause a runtime exception. This is because the library extends the `Object` prototype, which those two values don't inherit from, and so the execution throws due to a non-existing object member. But more recently (in this decade or so since it was originally released) there's been two developments that mitigate this issue and make the library more useful:

- There's new JavaScript syntax, the `?.` [optional chaining operator](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining), which precisely short-circuits the chain of invocations and returns `undefined` instead of throwing.
- The rise of TypeScript means that ([if set up correctly](https://www.typescriptlang.org/tsconfig/#strict)) we can opt into getting compilation errors when trying to access a member of a possibly nullish value.

I honestly do not love working with JS or even TS, but when I do, I like having something akin to a `|>` pipe operator available, common in functional programming such as the ML family of languages and Elixir. I'd much rather use a library of nice, functional utility functions that can operate on various forms of plain data (such as the TS-native [Remeda](https://remedajs.com/)) than dealing with objects with state and members and so on.
