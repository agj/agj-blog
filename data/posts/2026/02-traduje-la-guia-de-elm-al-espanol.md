---
title: Traduje “la guía” de Elm al español
date: "2026-02-15 00:33:00"
categories:
  - interactive
  - language
tags:
  - elm
  - translation
  - espanol
  - release
language: spa
external:
  mastodon-toot-id: "116071882462893259"
  devto-slug: "traduje-la-guia-de-elm-al-espanol-1mkj"
---

Escribí una [**traducción al español de “Introducción a Elm”**](https://agj.github.io/elm-guide-es/). Es un libro digital escrito por el mismo autor del lenguaje de programación Elm, Evan Czaplicki, como una forma accesible de aprender a programar usando el lenguaje. No sólo demuestra y explica el lenguaje mismo, sino que también presenta perspectivas y técnicas que yo considero muy valiosas, en un formato extremadamente accesible. Es una excelente manera de aprender programación funcional. Elm es un lenguaje y una comunidad de donde yo he aprendido muchísimo, y creo que el libro condensa una gran parte de ese valor. Con algo de suerte, esta traducción contribuirá un poquito a popularizar Elm y estas ideas dentro de los círculos hispanohablantes de programación.

Viendo el historial de Git, este proyecto de traducción lo empecé en agosto de 2024, o sea más o menos hace un año y medio. Obviamente no estuve constantemente trabajando en ello, sino que ocasionalmente me metía a trabajar en unas cuantas páginas, luego me ocupaba en otras cosas.

Una razón por la que quise traducir este libro es porque tenía ganas de practicar hacer una traducción técnica. Durante la última década y tanto he ocasionalmente hecho traducciones en forma remunerada, y he ido aprendiendo por mi cuenta sobre la disciplina. No me considero realmente un profesional, aunque sí es algo que me gusta hacer ocasionalmente, y no me considero malo haciéndolo. Definitivamente me falta teoría, eso sí.

Al traducir intenté ser muy preciso con lo técnico y consistente con los términos usados, pero también fui bastante libre en reformular la prosa de Evan para conservar ese tono cálido y transparente, que se traduce a un estilo bastante distinto en español. Por ejemplo, decidí usar consistentemente la primera persona plural (“hacemos”), versus una mezcla de segunda singular y primera plural (“you do”/“we do”) que usa el original. Así encuentro que suena menos acusatorio o demandante en español, un poquito más suave.

Hice el esfuerzo de usar lenguaje neutro al género, algo difícil de lograr totalmente en español, donde históricamente el género masculino se toma como “neutro”. El inglés no tiene este mismo problema, ya que en muy pocos casos se necesita ser explícito con el género, pero el texto original del libro sí tiene un enfoque inclusivo que definitivamente quise conservar. Encuentro particularmente importante evitar profundizar este sesgo en una industria tan masculinizada como la del software.

En el repositorio mismo anoté estas y algunas otras [directrices que definí para orientar la traducción](https://github.com/agj/elm-guide-es/blob/95b53f26ce5e20ccb923fd14a4a995b50e718e8f/CONTRIBUTING.md#traduciendo).

Me tomé la libertad de actualizar vínculos y referencias a recursos perdidos o desactualizados, también de reemplazar vínculos a contenido externo en inglés por una versión en español cuando hacía sentido. En muchos casos no existía esa alternativa, por lo que sería ideal eventualmente, por ejemplo, subtitular los videos usando [Amara](https://amara.org/), pero es una cantidad no trivial de trabajo extra. También estoy considerando traducir los artículos escritos por el mismo Evan, que vincula desde el libro, y dejarlos como apéndices. También faltan los diagramas y bastante código de ejemplo (los comentarios en particular) que aún están tal cual en inglés, lamentablemente.

Pero además de estos puntos, todavía permanece una otra gran limitación, y es que el libro hace uso de un REPL incrustado en varias páginas. El texto te invita a probar expresiones simples de código Elm y ver cómo se resuelven. Actualmente ese REPL no funciona en la traducción, porque depende de un servicio externo que Evan alberga en su servidor. Lo bueno es que ya hablé con él, y le propuse un PR que añade el dominio usado por esta traducción a la lista blanca que tiene el servicio del REPL. Evan me dijo que lo va a actualizar tan pronto se desocupe un poco, pero se nota que está bastante limitado de tiempo, así que seguramente pasará un rato antes de que lo haga.

Hablando de servidores y eso, la traducción la alojé en Github Pages porque es gratis, y así me ahorro un costo monetario que puede no ser grande, pero podría convertirse eventualmente en una razón para dejarla morir, si es que por alguna razón pierdo interés personal en mantenerla. Obviamente no tengo ninguna intención similar, pero tampoco sé en qué voy a estar dentro de unos cuantos años. Es algo que ya he visto ocurrir con sitios web relacionados con Elm, mantenidos presuntamente por gente que se alejó de la comunidad. Pero tal vez cambie de opinión si encuentro una buena solución.
