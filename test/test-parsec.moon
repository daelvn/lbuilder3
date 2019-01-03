import satisfy, char         from require "lbuilder.parsec.Char"
import parse, try, lookAhead from require "lbuilder.parsec.init"
import sign                  from require "ltypekit"
import typeof                from require "ltypekit.type"
import iostring              from require "lbuilder.parsec.init"
--char                            = require "ltypekit.types.Char"

parseres = (parse (try (char "x"))) "xyz"
print parseres, typeof parseres
