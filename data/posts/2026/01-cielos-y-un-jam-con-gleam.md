---
title: Cielos, y un jam con Gleam
date: "2026-01-20 02:46:00"
categories:
  - my-games
tags:
  - release
  - gleam
  - video-game
  - espanol
  - cielos
language: spa
external:
  mastodon-toot-id: "115925158259888401"
  devto-slug: "cielos-y-un-jam-con-gleam-4cpk"
---

Participé en [un _game jam_](https://gamejam.gleam.community/), o sea un evento grupal donde cada quien hace un videojuego durante un periodo de tiempo específico. Es el primer jam de juegos en torno al lenguaje de programación [Gleam](https://gleam.run/), un lenguaje joven que recién el 2024 [llegó a su versión 1.0](https://gleam.run/news/gleam-version-1/) y empezó a ganar tracción.

[Aquí puedes jugar **Cielos**](https://agj.github.io/cielos/), y [aquí está el **código fuente**](https://github.com/agj/cielos).

![Portada de un juego, con su título e instrucciones de juego. Atrás se ven estrellas amarillas flotando en perspectiva frente a un horizonte infinito de colores pasteles.](/files/2026/01-cielos-y-un-jam-con-gleam/cielos.png "Pantalla del juego.")

# Cielos

El juego que hice (a medias) se llama “Cielos”. El tema para el evento fue “Lucy in the sky with diamonds”. Lucy es el nombre de la mascota de Gleam, una estrellita rosada. Cada quién interpretó el tema a su manera, algunos haciendo mención directa a dicha mascota y a otros elementos de la cultura del lenguaje, otros al nombre Lucy, otros metieron diamantes por ahí.

Yo partí con la idea ambigua de hacer algo [tipo Jeff Minter](https://youtu.be/2J9SxTp0UbE), apropiado al “LSD” de la temática. Al final me quedé con la parte del “cielo”, y decidí hacer algo en un 3D no poligonal tipo Super Scaler o Modo 7. Me interesó finalmente el aspecto técnico de desarrollar este motorcito de visualización, y es en lo que más se me fue el tiempo durante ese espacio de nueve días. La estética de la tecnología de esos juegos de los arcades de Sega o de Super Nintendo la encuentro súper evocadora, y ocasionalmente me dan ganas de experimentar por ahí, como en [Cave Trip](/tag/?t=cave-trip) y (más o menos) en [Viewpoints](/tag/?t=viewpoints).

No me dio tiempo para permitir movilidad en las tres dimensiones (estaba pensando en algo un poco tipo el _all-range mode_ de Star Fox), pero traté que el movimiento se sienta placentero de controlar. Tuve que usar una estrategia totalmente diferente para el teclado y las pantallas táctiles. Para tacto usé rotación tipo “scroll”, que hoy no me convence del todo, se hace un poco engorroso de controlar.

Dadas las limitaciones de la librería gráfica que usé ([paint](https://hexdocs.pm/paint)), creé una tipografía muy simple usando líneas rectas en una grilla de 12×12, con los caracteres definidos directamente [en el código](https://github.com/agj/cielos/blob/be969c622af09b50b0877e84f739dd3da32ca553/src/text.gleam#L57). Por supuesto, sólo dibujé los caracteres que necesitaba para el juego.

Fui iterando y mucho se me quedó pendiente, pero en definitiva, hice algo que podría ser la base para un futuro juego más ambicioso. Quién sabe.

# Y qué tal ese Gleam

Gleam es un lenguaje que empecé a aprender recién ahora en noviembre, pero la verdad es que el proceso fue súper fluído. Me fui directo al [carril de aprendizaje en Exercism](https://exercism.org/tracks/gleam/concepts) ([aquí mis resultados](https://exercism.org/profiles/agj/solutions?track_slug=gleam)) y avancé sin ningún problema. Hoy día, después de este jam y de un par de semanas de experimentar usando la librería [Lustre](https://hexdocs.pm/lustre) para desarrollar frontend, me siento bien cómodo programando con él. Gleam puede compilar a dos objetivos: [BEAM](https://en.wikipedia.org/wiki/BEAM_%28Erlang_virtual_machine%29) (que lo pone en compañía con Erlang y Elixir) y JavaScript. Yo solamente conozco su lado JavaScript por ahora, hasta que me toque programar algún backend o algo por el estilo.

Es un lenguaje que parece heredar de OCaml, Elixir, Elm y Rust. Yo tengo bastante experiencia con Elm, un poquito con OCaml, y sólo he hecho algunos ejercicios con Rust y Elixir. Pero aunque no tuviera esa experiencia, Gleam sigue siendo un lenguaje súper simple, diseñado para ser fácil de aprender.

Voy a enumerar algunas cosas que me gustan de Gleam.

Primero lo más obvio, tiene un sistema de tipos muy simple pero muy sólido, con [tipos de datos algebraicos (ADTs)](https://es.wikipedia.org/wiki/Tipo_de_dato_algebraico) e inferencia de tipado a la [Hindley-Milner](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system), heredados de la familia de lenguajes [ML](https://es.wikipedia.org/wiki/ML_%28lenguaje_de_programaci%C3%B3n%29). El sistema de tipos se parece bastante al de Elm, pero más simple aún, donde los tipos de registro son tipos de suma con una sola variante.

```gleam
type MiRegistro {
  MiRegistro(un_campo: Int, otro_campo: String)
  // Aquí pueden ir otras variantes, y esto sería un tipo de suma.
}
```

Gleam tiene tan pocos conceptos que aprender que ni siquiera tiene “if/then/else”. Pero sí tiene un muy poderoso “pattern matching”, o búsqueda de patrones, que se puede usar con el mismo efecto:

```gleam
case mi_condicion {
  True -> cuando_si()
  False -> cuando_no()
}
```

Está muy pulida la experiencia de desarrollo. El CLI `gleam` es una herramienta todo en uno: inicializa tu proyecto, compila, formatea y tiene servidor de lenguaje para tu editor. El formato además sigue la filosofía de go fmt y de elm-format, o sea que nos evitamos tener que configurarlo, porque permite un sólo formato transversal y estándar.

Como último punto positivo no puedo dejar de mencionar su comunidad. Lamentablemente la mayoría de comunidades de software se concentra en lo técnico, en desmedro de lo humano. En el caso de Gleam, la comunidad es mucho más explícitamente inclusiva de lo que he visto hasta ahora, lo cual también [implica ser excluyente a las voces intolerantes](https://es.wikipedia.org/wiki/Paradoja_de_la_tolerancia). Esta es una cita directa de su web:

> Black lives matter. Trans rights are human rights. No nazi bullsh\*t.

Y bueno, Gleam definitivamente tiene mucho que me gusta, pero también tiene aspectos que me desilusionan. Esos aspectos que carece son justamente las cosas que me gustan de Elm, y que busco y espero en nuevos lenguajes funcionales, en lo posible.

Gleam no es un lenguaje puro. Cualquier función puede causar efectos, como hacer una llamada remota o yo qué sé. Me encantaría que tuviera gestión de efectos, y la librería Lustre al menos ofrece esa capacidad, pero no hay verificación a nivel del lenguaje. Además, la manera en que funciona su interfaz foránea con Erlang o JavaScript, que es arbitraria y sin chequeo de tipos, implica que el tipado no es sólido.

Estos puntos en contra son una real lástima, pero tomo lo bueno, y adopté Gleam como un lenguaje que toma mucho de lo que me gusta de Elm y lo hace un poco más versátil, pudiendo usarse en el backend sin problemas, por ejemplo. Su desarrollo es más sano y vigoroso, también, lo cual lo hace más fácil de promover con los pares y en el contexto laboral. Seguiré programando Gleam, seguro.
