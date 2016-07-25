# Extensions to the original PEG

This parser supports some extensions to the original PEG. 

## Namespaces

Namespaces allows to use rules from one grammar inside of other grammars. This allows, for example, to define a utility grammar with common rules (such as `EOF` rule) and use them in other, more specific grammars without copy-pasting.

### Declaration

A grammar text may start with namespace declaration. Namespace declaration starts with `@` symbol, which is followed by a name of the namespace. Name of a namespace obeys `Identifier` syntax from the original grammar.

    @Name
    # The rest of the grammar

If namespace declaration exists (it can be placed only before any rules, i.e. at the start of grammar text), every nonterminal symbol defined in the grammar is put into this namespace.

### Usage

`Identifier` syntax from the original paper is changed to allow to specify namespace. Namespace name is separated from identifier name by colon. Let's discuss namespaces usage on the following example.

    @M
    EOLN <- '\r\n'
    A <- EOLN
    B <- U:EOLN

Here, `A` refers to `EOLN` rule, which is defined here. Both `A` and `EOLN` belong to the same namespace `M`, so it's not required to explicitly specify `A <- M:EOLN`. However, `B` refers to `EOLN` rule from another namespace, `U`. This namespace may be defined in a separate grammar, e.g.

    # Another grammar
    @U
    EOLN <- '\n'

Use `MultiGrammar` class to parse input using multiple grammars. 

## Lazy Repetition

PEG's repetition expression `*` is greedy. This means, that if we want to skip some part of input, we need to do it using `!` expression:

    Rule <- (!Important .)* Important
    Important <- ...

To simplify this common pattern, we introduced non-greedy (or lazy) repetition expression: `*?`: 

    # This...
    Rule <- A*? B
    # ...is equivalent to 
    Rule <- (!B A)* B
    
So, the example above may be rewritten as

    Rule <- .*? Important
    Important <- ...
    
It is a syntax error, if there is no rule after `*?`.

## Sparse Blocks

Sparse block is a way to express common pattern, when we're only interested in certain blocks in the input and don't really bother about the rest. Like this:

    Top <- (Cool1 / .../ CoolN / .)*? !.
    Cool1 <- ...
    ...
    CoolN <- ...

With sparse blocks, we can rewrite it like this:

    Cool <- {
       Cool1 <- ...
       ...
       CoolN <- ...
    }
    Top <- {Cool} !.

The `Cool` block may be used in multiple places now. 
