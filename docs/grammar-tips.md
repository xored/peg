# Grammar Tips

## Getting Started

First, please, read the [original PEG paper](http://pdos.csail.mit.edu/~baford/packrat/popl04/peg-popl04.pdf), at least, sections 1 and 2, which give a good overview on what PEG is and what it can. There is also a grammar for PEG syntax there, and the parser follows this syntax. There is also a [wiki page](http://en.wikipedia.org/wiki/Parsing_expression_grammar), which can be very helpful. If you're familiar with contex-free grammars and things like BNF, you should have no trouble with understanding PEG.

## General Tips

### Order of definitions doesn't matter
If an expression refers to a nonterminal symbol, it doesn't matter if this symbol defined before or after the expression. The following two grammars are identical:

    Article <- Definite / Indefinite
    Indefinite <- 'a'
    Definite <- 'the'

    Indefinite <- 'a'
    Definite <- 'the'
    Article <- Definite / Indefinite

Although order of rules doesn't matter, it's more convenient to place rules from top to bottom, i.e. more general rules go before more specific ones. As you can see, the first grammar above is more readable, than the second one.

### EOF is '!.'
If you want that the entire input will be matched by the grammar, you have to explicitly tell about it. Otherwise, parser may parse only a portion of text and terminate. And this portion may be empty, so any input would match your grammar.

To specify that parser must consume the entire input for successful match, use `!.` expression. `.` means any symbol, `!.` means no more symbols. It's convenient to define a rule for this and use it, e.g.

    EOF <- !.

However, this technique must be used carefully, since it may lead to an infinite loop. Look at Common Pitfalls section for details.

### Prefer character classes over choice
Suppose, you need to specify that a character must be `#` or `$` or `@` or `&`. You can do this using choice expression:

    Char <- '#' / '$' / '@' / '&'

But there is a more concise way:

    Char <- [#$@&]

This way is preferred not only because it's short, but also because it will be parsed faster, than choice expression.

### '-' char in class
`-` char in a character class has a special treatment, but it still may be used by it's own. Consider the following rules:

    A <- [A-Z]
    B <- [-AZ]
    C <- [---]

The first rule matches any character from `A` to `Z`, but the second one matches only `-`, `A` and `Z`. The third rule matches single character: `-`. So, if you need `-` character by its own inside of a character class, just put it as a first or last character in the class.

## Common Pitfalls

Some common mistakes beginners make when writing PEG are explained here.

### Infinite loop
Be careful with rules which can match empty input.

* Repetition: `A*` can match empty input regardless of how `A` is defined.
* Predicates: also match empty input. E.g. `EOF` rule defined above.

When a rule which can match empty input is placed inside of uncontrolled repetition (directly or indirectly), it can lead to an inifite loop. E.g.

    A <- EOF*
    A <- (B*)*
    # Doesn't matter, how B is defined

Of course, such simple cases are easy to detect. But sometimes you may got the same behavior through a long chain of rule invocations, which is often hard to detect. More sophisticated example is below.

    Numbers <- Number*
    Number <- [0-9]+ / Spacing
    Spacing <- ' ' / '\t' / '\n' / EOF
    EOF <- !.

This grammar intended to match any input fully consists of numbers separated by whitespaces. However, the parser will report an infinite loop error, when the end of input is reached. It's because EOF is called inside of repetition indirectly through `Number <- Spacing <- EOF` chain. To fix it, `EOF` rule should be taken out from the loop:

    Numbers <- Number* EOF
    Number <- [0-9]+ / Spacing
    Spacing <- ' ' / '\t' / '\n'
    EOF <- !.

Old versions of the parser hangs when infinite loop is encountered. Current version detects this case and shows appropriate error message.