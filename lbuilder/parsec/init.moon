--> # lbuilder3/parsec
--> Parser combinators in Lua
-- 24.12.2018 (Christmas Eve!)
-- By daelvn
import sign   from require "ltypekit"
import typeof from require "ltypekit.type"
--> # Core
--> The code below contains the four most imporant functions to build lbuilder3/parsec
--> upon.

--> ## iostring
--> Creates a readable string handle just from any string. This is used by [satisfy](#satisfy) to consume input.
iostring = sign "string -> IOString"
iostring (s) -> setmetatable {
  value: s
  pointer: 1
  
  read:            =>
    print "iostring $ read #{@value\sub @pointer, @pointer}"
    @value\sub @pointer, @pointer
  consume: (ptr=1) =>
    print "iostring $ consume #{ptr}"
    @pointer += ptr
    @value\sub @pointer, @pointer
}, { __type: "IOString" }

ParseError = sign "string -> ParseError"
ParseError (s) -> setmetatable {
  message:    s
}, { __type: "ParseError" }

--> ## Parser
--> Quick way to create a parser
Parser = sign "/, / -> Parser"
Parser (p, call) -> setmetatable {}, {
  __type: "Parser"
  __call: (input) => call p, input
}

--> ## parse
--> This function will take a parser and an input, and then return its output, or an error, in appropiate
--> cases. This function is necessary so that we can convert the input into an [iostring](#iostring)
parse = sign "Parser -> string -> [ParseError|string]"
parse (parser) -> (s) -> parser iostring s

--> # Combinators
--> Parse combinators. The main part of the library.

--> ## try
--> Parses `p` and consumes input if success, otherwise doesn't.
try = sign "Parser -> Parser"
try (p) -> Parser p, (parser, input) ->
  initial = input.pointer
  if result = (parse parser), input
    switch typeof result
      when "string"
        result
      when "ParseError"
        input.pointer = initial
  else ParseError "parser did not return value"

--> ## lookAhead
--> Parses `p` but does not consume any input. If `p` fails and consumes any input, so does
--> `lookAhead`. Combine with [try](#try) if this is undesirable.
lookAhead = sign "Parser -> Parser"
lookAhead (p) -> Parser p, (parser, input) ->
  initial = input.pointer
  if result = (parse parser), input
    switch typeof result
      when "string"
        result
        input.pointer = initial
  else ParseError "parser did not return value"

{
  :iostring
  :ParseError, :Parser
  :parse
  :try, :lookAhead
}
