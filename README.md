## Prelude:
This file is a markdown-formatted file that I am using to document my work in the compiler. I started writing this file during lab 6 as a way to keep track and documentation of the ever-growing arsenal of files that go into programming and compiling my compiler.

### Message to the Professor:
If you're reading this, then I forgot to specify which files to zip into my archive. 

This code is not publically available on Github (nor is it even in a Git respository at the moment). 
After the conclusion of this course, I intend on posting this project to my Github page, using this markdown file as a reference for later.

# The Irony Language:

The [Irony language](https://www.cs.nmt.edu/~jeffery/courses/423/ironyref.html) is a language that aims to be a subset of the Rust programming language. 
The language specifications are at the discretion of the professor of the course ([Dr. Clinton Jeffery](https://www.cs.nmt.edu/~jeffery/)) and are continuously being updated and refined as our class treks on.
deep-seeded intricacies 
### Personal Approach:

In my personal approach to writing the Irony language, I am going to aim to be as close to Rust as I reasonably can, and adjust downward to the Irony specification. This is opposed to the option of aiming to just meet the Irony specification.

The reason I choose to take this approach is three-fold,
1. By aiming to be as Rust-like as possible, I further increase my own understanding of the Rust programming language. Rust is a memory-safe low level programming language that is becoming increasingly more common in the industry and will certainly be a valuable language to have experience in.
2. By aiming to be as Rust-like as possible, and then adjusting myself downwards when necessary, I will gain a better understanding of the deep-seeded intricacies of a compiler.
3. Shoot for the moon, even if you miss you'll land among the stars. By aiming for a proper Rust language, if I am unable to meet the specification, I will at least be closer to Irony. 

# The fec compiler
The fec compiler (pronounced like a word that can only be used once per PG-13 film) is an Irony compiler meant to convert `.rs` files into machine executable code. The name is a play on chemistry as iron carbonate, or an Irony Compiler, hence the FeC chemical symbol. 
### Sections:
1. Lexical Analysis (FLEX) - `rustlex.l`, `token.{c,h}`

The first step in compilation. In lexical analysis, we scan a file to break it apart into the words in our language and tokenize the elements within the file. 

2. Syntax Analysis (Bison/YACC) - `rustparse.y`, `tree.{c,h}`, `parserRules.h` `graphicTree.{c.h}`

The second step in compilation. In syntactical analysis, we match our tokens to a NFA and build an abstract syntax tree from the tokens. 

3. Semantic Analysis - `semanticAnalyzer.{c,h}`, `semanticRules.h`, `symtab.{c,h}`

During semantic analysis, we look through a file to build our symbol table and check variables in scope. At this stage we ensure types are not mismatched. 

4. Intermediate Code Generation
5. Optimization
6. Code Generation

# File Explanation:

`main.c`: The main file responsible for reading input, calling our compiler functions in proper order, printing out error messages, and freeing all used memory upon completion.

`Makefile`: The most meta file in existence. It compiles our code down into an executable file so that we can have a working compiler to compile down other code into working executable files (eventually).

### Lexical Analysis
`rustlex.l`: This is a flex file for lexical analysis. This file is responsible for building our tokens that are parsed during lexical analysis. Additionally, it has the responsibility of building the leafs of our AST. Our syntax analyzer calls the lexical analyzer by using `yylex()` to get the next token in the file.

`token.{c,h}`: Contains the definition of the `token` struct, as well as a constructor and destructor for the `token` struct type.

### Syntax Analysis
`rustparse.y`: This is a bison file for syntax analysis. Using a deterministic context free grammar, we build an abstract syntax tree from the tokens provided by `yylex()`. Defines the constants used by `rustlex.l`

`tree.{c,h}`: Cntains the definition of the `tree` struct, as well as methods for constructing, destructing and printing trees. Contains a private pointer to a root that can only be modified by using `getTreeRoot()` and `setTreeRoot()`. Setting the tree root is only done by `rustparse.y`.

`parserRules.h`: Defines the constant values used as rules during syntax analysis

`graphicTree.{c,h}`: Used only when the code is ran with the `-dot` argument. Generates a `.dot` file as output, which can be used to generate a PNG representation of our AST.

### Semantic Analysis
`semanticAnalyzer.{c,h}`:

`semanticRules.h`: Defines the constant values used as rules during semantic analysis.

`symtab.{c,h}`: Contains the definitions of the `SymbolTableEntry` and `SymbolTable` data types, as well as methods for searching for and adding symbols to the symbol table. 

## Data Types