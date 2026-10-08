# language: es
Característica: Pasos localizados
  Macros y definiciones de pasos sin macro, en español, con una tabla, un texto y un esquema.

  Escenario: Un paso en español
    Dado tengo 5 pepinos
    Entonces la cesta tiene 5 pepinos

  Escenario: Una tabla y un texto
    Dado tengo 1 pepinos
    Y la cesta tiene estos pepinos:
      | color | cantidad |
      | green | 2        |
    Y una nota en la cesta:
      """
      Mantener frescos.
      """
    Entonces la cesta tiene 3 pepinos
    Y la nota dice "Mantener frescos."

  Esquema del escenario: Contar los pepinos
    Dado tengo <inicio> pepinos
    Entonces la cesta tiene <inicio> pepinos

    Ejemplos:
      | inicio |
      | 1      |
      | 4      |

  Escenario: Un paso en español con una expresión regular
    Dado tengo 7 pepinos en la cesta
    Entonces la cesta tiene 7 pepinos
