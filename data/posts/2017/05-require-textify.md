---
title: require-textify
date: 11
hour: 22
categories:
- interactive
tags:
- javascript
- library
- release
---

I'm not sure why I didn't post about this in 2016, when I made it, since I did post about [two other packages](http://blog.agj.cl/2015/12/two-npm-packages/) I published on [npm](https://www.npmjs.com/) that one time. This one's a small [Browserify](http://browserify.org/) plugin to _require()_ files as UTF-8 strings, rather than as javascript code. There are a few alternatives out there, particularly [stringify,](https://johnpostlethwait.github.io/stringify/) but for my use case at that moment I needed something more versatile than just selecting based on extension. My implementation is simple and works, using glob patterns for selection. I certainly could have chosen a better name for it, though...

See [**require-textify**'s Github repository.](https://github.com/agj/require-textify)
