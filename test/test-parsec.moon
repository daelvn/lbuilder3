import satisfy, char         from require "lbuilder.parsec.Char"
import parse, try, lookAhead from require "lbuilder.parsec.init"
import sign                  from require "ltypekit"
import typeof                from require "ltypekit.type"
import iostring              from require "lbuilder.parsec.init"
--char                            = require "ltypekit.types.Char"

--typeof\add "char", char.char_resolver
--parseres = (parse (satisfy (sign "char -> boolean") (c) -> c == "x")) "xyz"
parseres = (parse (char "x")) "xyz"
print parseres, typeof parseres
print (char "x") iostring "xyz"
