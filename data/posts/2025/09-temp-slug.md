---
title: Some title
day-of-month: 8
date: "2025-08-06 00:34:00"
categories:
  - interactive
tags:
  - blog
  - elm
  - nix
  - web
language: eng
---

Desde hace un tiempo que en cualquier proyecto personal de código que empiezo, termino usando tres tecnologías: [Nix][nix], [Nushell][nushell] y [Just][just]. En este artículo quiero compartir la forma en que las uso para configurar las dependencias del proyecto, escribir scripts, y definir sus tareas de desarrollo.

Vamos a partir viendo el manejo de dependencias usando Nix.

[nix]: https://nixos.org/
[nushell]: https://www.nushell.sh/
[just]: https://just.systems/

# Nix para declarar dependencias

[Nix](https://nixos.org/) es un ecosistema enorme, muy versátil, pero en este contexto lo que nos interesa es que podemos usar esta herramienta para declarar todas las utilidades necesarias para correr un proyecto, compilarlo, hacer linting, etc. Es compatible con casi cualquier entorno tipo Unix, o sea Linux, macOS y Windows bajo WSL.

En particular, lo que vamos a usar es algo llamado “flake”. Este es un archivo `flake.nix` que ponemos en la raíz de nuestro proyecto, y es donde declararaemos los paquetes que necesita.

Partamos con un ejemplo simple:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {system = "aarch64-darwin";};
  in {
    devShell."aarch64-darwin" = pkgs.mkShell {
      buildInputs = [
        pkgs.elmPackages.elm
        pkgs.elmPackages.elm-format
        pkgs.elmPackages.elm-test
        pkgs.just
        pkgs.nushell
      ];
    };
  };
}
```

Con esto, hemos definido un entorno que contiene algunas herramientas para un proyecto Elm, además de los binarios de Nushell y Just, a los que me voy a referir más abajo. Así como está, esto sólo va a funcionar en un Mac de los con Apple Silicon. Después vamos a desarrollar este ejemplo para entenderlo mejor y hacerlo más versátil, pero por ahora partamos por lo básico.

Teniendo este archivo, si corremos el comando `nix develop` vamos a entrar a un shell que contiene todas las herramientas declaradas en nuestro `flake.nix`. Para salir basta con correr el comando `exit`, y veremos que ya no tenemos disponibles las herramientas—son totalmente locales al proyecto.

```sh
$ nix develop
$ which elm
/nix/store/6hx8g6k7ihgaqvy1i0ydiy7v13s04pf4-elm-0.19.1/bin/elm

$ exit
exit

$ which elm
elm not found
```

La primera vez se generará un archivo `flake.lock`, el cual podemos integrar en Git (o tu VCS preferido) para mantener la versión exacta de estas dependencias. Luego se descargarán algunos binarios en caché o se compilarán las dependencias desde su código fuente. Pero eso ocurrirá sólo la primera vez, o cuando quieras cambiar las dependencias, ya que se almacenará todo en el “store” global de Nix.

# Nushell para escribir scripts

[Nushell][nushell] es una alternativa a Bash o zsh. La diferencia es que en vez de seguir los lineamientos [POSIX](https://es.wikipedia.org/wiki/POSIX) e interactuar sólo con texto plano, trabajamos con datos estructurados. Básicamente, es un shell y lenguaje que reemplaza la necesidad de Bash, grep, sed, awk, jq, curl y muchas otras utilidades de línea de comandos frecuentemente usadas para procesar datos.

Igual se ajusta hasta cierto punto a nuestras expectativas como usuarios de Bash y similares. Por ejemplo, en un shell Nushell el comando `ls` funciona como es de esperarse:

```sh
$ ls
╭───┬────────────┬──────┬───────┬─────────────╮
│ # │    name    │ type │ size  │  modified   │
├───┼────────────┼──────┼───────┼─────────────┤
│ 0 │ flake.lock │ file │ 569 B │ 8 hours ago │
│ 1 │ flake.nix  │ file │ 405 B │ 7 hours ago │
╰───┴────────────┴──────┴───────┴─────────────╯
```

Pero esta salida no es puramente texto. En realidad lo que hemos obtenido es una tabla con filas y columnas. Mira el tipo de cosas que podemos hacer con sólo Nushell:

```sh
$ ls | where name =~ '[.]lock$' | get 0.name | open
::: | from json | get nodes.nixpkgs.locked.lastModified
::: | $in * 1_000_000_000 | into datetime
Tue, 5 Aug 2025 11:35:34 +0000 (2 days ago)
```

Obviamente este ejemplo es puramente demostrativo, pero fíjate: estamos listando archivos, filtrando en base a un regex, sacando el nombre del primero en la lista, leyendo el contenido del archivo, interpretándolo como JSON, recuperando un valor numérico dentro del JSON, multiplicando para convertir segundos a nanosegundos, y finalmente convirtiendo eso a una fecha.

Es tan práctico que lo tengo como mi shell por defecto. Pero para el caso de este artículo, lo relevante es su utilidad para escribir scripts simples y legibles que transforman archivos, levantan servicios, recuperan datos de internet, y más. Los archivos llevan la extensión `.nu`.

Veamos un pequeño ejemplo. Este es un script que actualiza nuestra lista de exclusiones de robots de IA, con datos que descargamos del [Github del proyecto ai.robots.txt](https://github.com/ai-robots-txt/ai.robots.txt/).

```nu
# Algunas constantes.
let aiRobotsTxtBaseUrl = "https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main"
let startMarkerLine = "# Start ai.robots.txt"
let endMarkerLine = "# End ai.robots.txt"

# Una pequeña función para simplificar el código más adelante.
def splitLines [] {
  split row "\n"
}

# Función que procesa los datos para un archivo específico, ya que son
# dos los que queremos actualizar.
def updateFile [$filename] {
  # Leemos el archivo local y lo dejamos en la variable como una lista
  # de líneas.
  let localLines = open $"./public/($filename)" | splitLines
  # Lo mismo para el archivo remoto.
  let updateLines = http get $"($aiRobotsTxtBaseUrl)/($filename)" | splitLines

  # El archivo local tiene líneas que marcan el comienzo y el final
  # del contenido que queremos actualizar, marcados por las constantes
  # de arriba de nombre `$startMarkerLine` y `$endMarkerLine`. En base
  # a ese contenido, cortamos la lista para recuperar el contenido
  # que queremos mantener, el cual viene antes y después dentro del
  # archivo.
  let firstSplit = $localLines | split list $startMarkerLine
  let linesBeforeUpdate = $firstSplit | get 0
  let secondSplit = $firstSplit | get 1 | split list $endMarkerLine
  let linesAfterUpdate = $secondSplit | get 1

  # Insertamos las líneas provenientes del archivo remoto en la mitad,
  # concatenando todo en una misma lista.
  let updatedLines = (
    $linesBeforeUpdate
    ++ [$startMarkerLine]
    ++ $updateLines
    ++ [$endMarkerLine]
    ++ $linesAfterUpdate
  )

  # Sobreescribimos el archivo antiguo con las nuevas líneas.
  $updatedLines | str join "\n" | save --force $"./public/($filename)"
}

# Usamos la función definida arriba para procesar dos archivos.
updateFile ".htaccess"
updateFile "robots.txt"
```

No sé lo que pienses tú, pero yo creo que queda un código extremadamente legible y conciso. Es fácil de escribir, trae “pilas incluídas” como quien dice, con soporte para procesar muchos formatos de archivo. Y cuando hay algo que no se puede hacer con Nushell, puedes echar mano a cualquier herramienta de línea de comandos, idéntico a como haríamos en un script de Bash.

El lenguaje Nushell toma las “pipes” (`|`) de los shell Unix y las combina con estructuras de datos inmutables. Es un lenguaje bastante funcional, de tipado dinámico pero estricto, o sea que si una función recibe un valor con un tipo inesperado, la ejecución falla con un mensaje bien explícito, como este:

```sh
$ ["hola", "cómo", "estás"] | date to-timezone "UTC"
Error: nu::parser::input_type_mismatch

  × Command does not support list<string> input.
   ╭─[entry #6:1:31]
 1 │ ["hola", "cómo", "estás"] | date to-timezone "UTC"
   ·                             ────────┬───────
   ·                                     ╰── command doesn't support list<string> input
   ╰────
```

# Just para definir tareas

Just es una herramienta con un alcance muy moderado: permitir definir tareas de ejecución
