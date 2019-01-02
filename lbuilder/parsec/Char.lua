local sign
sign = require("ltypekit").sign
local typeof
typeof = require("ltypekit.type").typeof
local char = require("ltypekit.types.Char")
local Parser
Parser = require("lbuilder.parsec.init").Parser
typeof:add("char", char.char_resolver)
local satisfy = sign("(char -> boolean) -> Parser")
satisfy(function(f)
  return Parser(f, function(cond, input)
    do
      local read = input:read()
      if read then
        if cond(read) then
          return input:consume()
        else
          return ParseError("unexpected " .. tostring(read))
        end
      else
        return ParseError("could not read input")
      end
    end
  end)
end)
local isChar, isControl, isSpace, isLower, isUpper, isAlpha, isLetter, isAlphaNum, isPrint, isDigit, isOctDigit, isHexDigit, isPunctuation
isChar, isControl, isSpace, isLower, isUpper, isAlpha, isLetter, isAlphaNum, isPrint, isDigit, isOctDigit, isHexDigit, isPunctuation = char.isChar, char.isControl, char.isSpace, char.isLower, char.isUpper, char.isAlpha, char.isLetter, char.isAlphaNum, char.isPrint, char.isDigit, char.isOctDigit, char.isHexDigit, char.isPunctuation
local anyChar = sign("Parser")
anyChar(function()
  return satisfy(function()
    return true
  end)
end)
char = sign("char -> Parser")
char(function(c)
  return satisfy((sign("char -> boolean"))(function(cc)
    return c == cc
  end))
end)
local octDigit = sign("Parser")
octDigit(function()
  return satisfy(isOctDigit)
end)
local hexDigit = sign("Parser")
hexDigit(function()
  return satisfy(function(c)
    return isHexDigit(c)
  end)
end)
local digit = sign("Parser")
digit(function()
  return satisfy(function(c)
    return isDigit(c)
  end)
end)
local letter = sign("Parser")
letter(function()
  return satisfy(function(c)
    return isAlpha(c)
  end)
end)
local alphaNum = sign("Parser")
alphaNum(function()
  return satisfy(function(c)
    return isAlphaNum(c)
  end)
end)
local lower = sign("Parser")
lower(function()
  return satisfy(function(c)
    return isLower(c)
  end)
end)
local upper = sign("Parser")
upper(function()
  return satisfy(function(c)
    return isUpper(c)
  end)
end)
local tab = sign("Parser")
tab(function()
  return satisfy(function(c)
    return c:match("\t")
  end)
end)
local endOfLine = sign("Parser")
endOfLine(function()
  return satisfy(function(c) end)
end)
local crlf = sign("Parser")
crlf(function()
  return satisfy(function(c)
    return c:match("\r\n")
  end)
end)
local newline = sign("Parser")
newline(function()
  return satisfy(function(c)
    return c:match("\n")
  end)
end)
local space = sign("Parser")
space(function()
  return satisfy(function(c)
    return isSpace(c)
  end)
end)
lower = sign("Parser")
lower(function()
  return satisfy(function(c)
    return isLower(c)
  end)
end)
local oneOf = sign("string -> Parser")
oneOf(function(set)
  return satisfy(function(c)
    return c:match("[" .. tostring(set) .. "]")
  end)
end)
local noneOf = sign("string -> Parser")
noneOf(function(set)
  return satisfy(function(c)
    return c:match("[^" .. tostring(set) .. "]")
  end)
end)
return {
  satisfy = satisfy,
  anyChar = anyChar,
  char = char,
  octDigit = octDigit,
  hexDigit = hexDigit,
  digit = digit,
  letter = letter,
  alphaNum = alphaNum,
  lower = lower,
  upper = upper,
  tab = tab,
  endOfLine = endOfLine,
  crlf = crlf,
  newline = newline,
  space = space,
  oneOf = oneOf,
  noneOf = noneOf
}
