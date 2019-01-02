local sign
sign = require("ltypekit").sign
local typeof
typeof = require("ltypekit.type").typeof
local ts = (require("tableshape")).types
local Macro = sign("string, table -> Macro")
Macro(function(name, macrot)
  macrot.name = name
  return setmetatable(macrot, {
    __type = "Macro"
  })
end)
local MacroError = sign("string -> MacroError")
MacroError(function(s)
  return setmetatable({
    tracelimit = 5,
    message = s,
    extra = "lbuilder3/macro"
  }, {
    __type = "MacroError"
  })
end)
local shape_Macro = ts.shape({
  condition = ts.string + ts.array_of(ts.shape({
    ts.string,
    ts.string
  })),
  capture = ts.string + ts.array_of(ts.string),
  replace = ts.string + ts.array_of(ts.string),
  stack = (ts.array_of(ts.shape({
    ts.string,
    ts.string
  }))):is_optional()
})
local get_least_length = sign("table, table -> number")
get_least_length(function(a, b)
  if #a > #b then
    return #a
  else
    return #b
  end
end)
local _n = 0
local n
n = function()
  _n = _n + 1
  return _n
end
local parse = sign("Macro -> table -> [MacroError|string]")
parse(function(macro)
  return function(stack)
    return function(input)
      local push
      push = function(v)
        return table.insert(stack, 1, v)
      end
      local peek
      peek = function()
        return stack[1]
      end
      local pop
      pop = function()
        return table.remove(stack, 1)
      end
      print(n())
      local _exp_0 = typeof(macro.condition)
      if "string" == _exp_0 then
        print(n())
        if not ((input:match(macro.condition))) then
          MacroError("condition not matched")
        end
      elseif "table" == _exp_0 then
        print(n())
        local _list_0 = macro.condition
        for _index_0 = 1, #_list_0 do
          local cond = _list_0[_index_0]
          if cond[1] == "pattern" then
            print(n())
            if not ((input:match(cond[2]))) then
              MacroError("condition not matched")
            end
          elseif cond[1] == "peek" then
            print(n())
            if not ((peek() == cond[2])) then
              MacroError("unexpected value in stack")
            end
          end
        end
      end
      local ll
      if ((typeof(macro.capture)) == "table") and ((typeof(macro.replace)) == "table") then
        ll = get_least_length(macro.capture, macro.replace)
        assert((ll > 0), "cannot have an empty table")
      else
        ll = 1
        macro.capture = {
          macro.capture
        }
        macro.replace = {
          macro.replace
        }
      end
      for i = 1, ll do
        input = input:gsub(macro.capture[i], macro.replace[i])
      end
      if macro.stack then
        local _list_0 = macro.stack
        for _index_0 = 1, #_list_0 do
          local oper = _list_0[_index_0]
          if oper[1] == "push" then
            push(oper[2])
          elseif oper[1] == "pop" then
            print(n())
            if not ((pop() == oper[2])) then
              MacroError("unexpected value in stack after replacements")
            end
          end
        end
      end
      print(n())
      return input
    end
  end
end)
local x = Macro("test/x", {
  condition = "x.x",
  capture = "x(.)x",
  replace = "xx%1"
})
print(((parse(x))({ }))("xyx"))
return {
  Macro = Macro,
  MacroError = MacroError,
  parse = parse
}
