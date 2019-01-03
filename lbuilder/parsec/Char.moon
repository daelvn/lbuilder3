--> # lbuilder3/parsec
--> Parser combinators in Lua. Char module.
-- 02.01.2019
-- By daelvn
import sign   from require "ltypekit"
import typeof from require "ltypekit.type"
char =             require "ltypekit.types.Char"
import Parser from require "lbuilder.parsec.init"

--> ## Import Char type
typeof\add "char", char.char_resolver

--> ## satisfy
--> This function makes a parser out of a function `string -> boolean`. If the input character can be consumed,
--> it should return true, otherwise false. This function creates a Parser type from a string. The input it takes is,
--> indeed, an [iostring](#iostring).
satisfy = sign "(char -> boolean) -> Parser"
satisfy (f) -> Parser f, (cond, input) ->
  if read = input\read!
    if cond read
      input\consume!
      input\rest!
    else ParseError "unexpected #{read}"
  else ParseError "could not read input"

--> # Characters (Parsec: Text.Parsec.Char)
--> Below is a collection of functions built on top of [satisfy](#satisfy), trying to match
--> most of the ones in Haskell's parsec.
import isChar, isControl, isSpace, isLower, isUpper, isAlpha, isLetter, isAlphaNum,
       isPrint, isDigit, isOctDigit, isHexDigit, isPunctuation
  from char

--> ## anyChar
--> Matches any character.
anyChar = sign "Parser"
anyChar -> satisfy -> true

--> ## char
--> Matches a character `c`
char = sign "char -> Parser"
char (c) -> satisfy (sign "char -> boolean") (cc) -> c == cc

--> ## octDigit
--> Matches a digit from 0 to 7
octDigit = sign "Parser"
octDigit -> satisfy isOctDigit

--> ## hexDigit
--> Matches a digit from 0 to 8 and letters a-f and A-F
hexDigit = sign "Parser"
hexDigit -> satisfy isHexDigit

--> ## digit
--> Parses a digit from 0 to 9
digit = sign "Parser"
digit -> satisfy isDigit

--> ## letter
--> Parses alphabetic characters (lower-case, upper-case and title-case letters, plus letters of caseless scripts and modifiers letters).
letter = sign "Parser"
letter -> satisfy isAlpha

--> ## alphaNum
--> Parses alphabetic or numeric characters.
alphaNum = sign "Parser"
alphaNum -> satisfy isAlphaNum

--> ## lower
--> Parses lower-case alphabetic characters (letters).
lower = sign "Parser"
lower -> satisfy isLower

--> ## upper
--> Parses uppercase-case alphabetic characters (letters).
upper = sign "Parser"
upper -> satisfy isUpper

--> ## tab
--> Parses specifically \t.
tab = sign "Parser"
tab -> satisfy (c) -> c\match "\t"

--> ## endOfLine
--> Parses an end of line.
--> Requires <|>
endOfLine = sign "Parser"
endOfLine -> satisfy (c) ->

--> ## crlf
--> Parses \r\n.
crlf = sign "Parser"
crlf -> satisfy (c) -> c\match "\r\n"

--> ## newline
--> Parses \n.
newline = sign "Parser"
newline -> satisfy (c) -> c\match "\n"

--> ## space
--> Parses any space character, and the control characters \t, \n, \r, \f, \v.
space = sign "Parser"
space -> satisfy isSpace

--> ## string
--> Parses several characters
--> TODO does require some engineering, and skipMany probably
lower = sign "Parser"
lower -> satisfy isLower

--> ## oneOf
--> Advances on any of the characters in the set.
oneOf = sign "string -> Parser"
oneOf (set) -> satisfy (c) -> c\match "[#{set}]"

--> ## noneOf
--> Advances when the character is not in the set.
noneOf = sign "string -> Parser"
noneOf (set) -> satisfy (c) -> c\match "[^#{set}]"

{
  :satisfy
  :anyChar, :char
  :octDigit, :hexDigit, :digit
  :letter, :alphaNum, :lower, :upper
  :tab, :endOfLine, :crlf, :newline, :space
  :oneOf, :noneOf
}
