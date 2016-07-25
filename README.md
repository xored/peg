The implementation of PEG parser in [Fantom](http://fantom.org/).

The main resources about PEG:

* [PEG paper](http://pdos.csail.mit.edu/~baford/packrat/popl04/peg-popl04.pdf) by Bryan Ford
* [PEG wiki page](http://en.wikipedia.org/wiki/Parsing_expression_grammar)

Also some docs are available in the `docs` directory:

* Extensions to the original PEG this parser recognizes
* Grammar writing tips
* Grammar examples

This parser is licensed under [EPL](https://en.wikipedia.org/wiki/Eclipse_Public_License).

Special feature of this parser is that it allows to parse really big files, even if the file and/or the parsed tree wouldn't fit into RAM.

Another feature is that it is incremental: you can parse a part of a text, then stop it and parse the rest of the text afterwards. It saves time in situations, when you're getting the text slowly, because it allows to start parsing very early instead of waiting for the full text.

Meta grammar is not hardcoded and can be changed using the parser's API (only PEG expressions are hardcoded). This means, that you can modify/extend the grammar relatively easily, without patching the parser itself.
