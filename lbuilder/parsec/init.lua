local sign
sign = require("ltypekit").sign
local typeof
typeof = require("ltypekit.type").typeof
local iostring = sign("string -> IOString")
iostring(function(s)
  return setmetatable({
    value = s,
    pointer = 1,
    read = function(self)
      print("iostring $ read " .. tostring(self.value:sub(self.pointer, self.pointer)))
      return self.value:sub(self.pointer, self.pointer)
    end,
    consume = function(self, ptr)
      if ptr == nil then
        ptr = 1
      end
      print("iostring $ consume " .. tostring(ptr))
      self.pointer = self.pointer + ptr
      return self.value:sub(self.pointer, self.pointer)
    end
  }, {
    __type = "IOString"
  })
end)
local ParseError = sign("string -> ParseError")
ParseError(function(s)
  return setmetatable({
    message = s
  }, {
    __type = "ParseError"
  })
end)
local Parser = sign("/, / -> Parser")
Parser(function(p, call)
  return setmetatable({ }, {
    __type = "Parser",
    __call = function(self, input)
      return call(p, input)
    end
  })
end)
local parse = sign("Parser -> string -> [ParseError|string]")
parse(function(parser)
  return function(s)
    return parser(iostring(s))
  end
end)
local try = sign("Parser -> Parser")
try(function(p)
  return Parser(p, function(parser, input)
    local initial = input.pointer
    do
      local result = (parse(parser)), input
      if result then
        local _exp_0 = typeof(result)
        if "string" == _exp_0 then
          return result
        elseif "ParseError" == _exp_0 then
          input.pointer = initial
        else
          return ParseError("parser did not return value")
        end
      end
    end
  end)
end)
local lookAhead = sign("Parser -> Parser")
lookAhead(function(p)
  return Parser(p, function(parser, input)
    local initial = input.pointer
    do
      local result = (parse(parser)), input
      if result then
        local _exp_0 = typeof(result)
        if "string" == _exp_0 then
          local _ = result
          input.pointer = initial
        else
          return ParseError("parser did not return value")
        end
      end
    end
  end)
end)
return {
  iostring = iostring,
  ParseError = ParseError,
  Parser = Parser,
  parse = parse,
  try = try,
  lookAhead = lookAhead
}
