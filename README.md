# **Dyca**
Dominant Yet Calmly Angelic

Dyca is a lightweight and minimalistic interpreted programming language designed with clarity, silence, and elegance at its core.

---

## What is Dyca?

Dyca is an interpreted scripting language built using Dlang.
It prioritizes readability, simplicity, and a modular file structure inspired by Dlang's `module` system , using `export` and `import` as core keywords.

Dyca is meant to be:

* **Beautiful** to read
* **Lightweight** to run
* **Minimal** to maintain
* **Powerful** in concept

---

## Core Features

* Dynamically typed
* Implicit variable declarations
* Simple functions with `function`
* Clean control flow with `if`, `else if`, `else`, and `for`
* No external dependencies , self-contained interpreter in D
* Modular system via `export` and `import`
* Minimal built-in functions: only `print()` and `input()`

---

## File Structure

* Each `.dyca` file can export a logical namespace
* Imports follow folder structure (`import utils.math`)
* No REPL , only direct file execution (`dyca path/to/file.dyca`)

---

## Example

```dyca
export utils.math

function square(x) {
    return x * x
}
```

```dyca
import utils.math

print(math.square(5))
```

---

## Philosophy

Dyca was not created to impress.
It was born from restraint.
In a world of noise, Dyca chooses stillness.
In an age of complexity, Dyca offers elegance.

---

## Requirements

* D compiler (tested on `ldc2` and `dmd`)
* No third-party dependencies
* No `dub` required

---

## Building

Compile with:

```sh
dmd src/main.d -of=dyca
```

or if you're using LDC:

```sh
ldc2 src/main.d -of=dyca
```

Then run a file:

```sh
./dyca scripts/example.dyca
```

---

## License

MIT License.

---

If you're here, you've already heard Dyca's dance.

---

