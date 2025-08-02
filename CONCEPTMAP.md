# Dyca

**A lightweight and aesthetically minimal programming language, designed to be soft in syntax yet powerful in capability.**

---

### Language Philosophy

* Elegance through simplicity: Syntax should express logic, not noise.
* Minimal surface, deep core: Avoid bloated features; empower the essentials.
* Designed for the command line and embedding: CLI scripting and embeddable interpreters as first-class citizens.
* Modularity inspired by Dlang: Files are units of logic; imports follow clear paths.
* Human-readable, machine-lean: Syntax should be expressive for the writer and efficient for the interpreter.

---

### Syntax Overview

* File extension: `.dyca`
* Dynamically typed
* No variable declaration keyword
* Functions declared with `function`
* Control flow: `if`, `else if`, `else`, `for`
* Modules declared with `export`, loaded via `import`
* Only two built-in functions by default: `print`, `input`
* No REPL, Dyca runs files directly

---

### Variables

Variables are declared by simple assignment.

```dyca
x = 42
name = "Dyca"
isValid = true
```

They can be reassigned to values of any type without redeclaration.

---

### Data Types

* Number
* String
* Boolean (`true`, `false`)
* Null (`null`)

---

### Functions

```dyca
function greet(name) {
    return "Hello " + name
}

print(greet("Dyca"))
```

---

### Control Flow

```dyca
if (x > 0) {
    print("positive")
} else if (x < 0) {
    print("negative")
} else {
    print("zero")
}
```

```dyca
for (i = 0; i < 5; i = i + 1) {
    print(i)
}
```

---

### Comments

Only `//` style comments are supported.

```dyca
// this is a comment
```

---

### Built-in Functions

Only two are included by default:

```dyca
print(value)
input(prompt)
```

All other functionality is expected to be implemented via external modules or extensions.

---

### Modular System

Modules are based on files, with paths reflecting the structure of the export.

```dyca
export utils.math
```

To use it:

```dyca
import utils.math
print(math.square(4))
```

Or with alias:

```dyca
import utils.math as m
print(m.square(9))
```

**Example structure:**

```
project/
├── main.dyca
└── utils/
    └── math.dyca
```

**Content of `utils/math.dyca`:**

```dyca
export utils.math

function square(x) {
    return x * x
}
```

**Content of `main.dyca`:**

```dyca
import utils.math

print(math.square(5))
```

---

### Operators

**Arithmetic:** `+`, `-`, `*`, `/`, `%`
**Comparison:** `==`, `!=`, `<`, `>`, `<=`, `>=`
**Logical:** `&&`, `||`, `!`

---

### Example Programs

**Hello World**

```dyca
print("Hello from Dyca")
```

**Array Sum**

```dyca
arr = [1, 2, 3, 4]
sum = 0

for (i = 0; i < 4; i = i + 1) {
    sum = sum + arr[i]
}

print(sum)
```

**Recursive Fibonacci**

```dyca
function fib(n) {
    if (n <= 1) {
        return n
    } else {
        return fib(n - 1) + fib(n - 2)
    }
}

print(fib(10))
```

**Module Example**

```dyca
// File: string/tools.dyca
export string.tools

function upper(s) {
    // implementation pending
    return ...
}
```

```dyca
// File: main.dyca
import string.tools as str

name = input("Enter your name: ")
print(str.upper(name))
```

---

### Simplified Grammar (EBNF)

```ebnf
Program         = { Statement } ;
Statement       = Assignment | FunctionDecl | IfStmt | ForLoop | ImportStmt | ExportStmt | ExpressionStmt ;

Assignment      = Identifier "=" Expression ;
FunctionDecl    = "function" Identifier "(" [ ParamList ] ")" Block ;
ParamList       = Identifier { "," Identifier } ;

IfStmt          = "if" "(" Expression ")" Block { "else if" "(" Expression ")" Block } [ "else" Block ] ;
ForLoop         = "for" "(" Assignment ";" Expression ";" Assignment ")" Block ;

ImportStmt      = "import" Identifier { "." Identifier } [ "as" Identifier ] ;
ExportStmt      = "export" Identifier { "." Identifier } ;

Block           = "{" { Statement } } ;
ExpressionStmt  = Expression ;

Expression      = Literal | Identifier | FunctionCall | BinaryOperation ;
FunctionCall    = Identifier "(" [ ArgumentList ] ")" ;
ArgumentList    = Expression { "," Expression } ;

BinaryOperation = Expression Operator Expression ;
Operator        = "+" | "-" | "*" | "/" | "%" |
                  "==" | "!=" | "<" | ">" | "<=" | ">=" |
                  "&&" | "||" ;

Literal         = Number | String | Boolean | "null" ;
Identifier      = letter { letter | digit | "_" } ;
Number          = digit { digit } ;
String          = '"' { character } '"' ;
```

---

# The Dance

Dyca is not merely a tool, nor just another language in the sea of interpreters.
Dyca is the whisper of order amidst chaos, born not to dominate the machine, but to gracefully guide logic with minimal noise and maximum expression.

It stands for *Dominant Yet Calmly Angelic*.
Not only in name, but in every line, every structure, and every thought behind it.
Dyca is code in its most human, most silent, most composed form, a language to speak with elegance, and build with love.

It was created not from ambition to compete, but from the quiet desire to create something pure,
something soft yet firm, something you can trust.

---
