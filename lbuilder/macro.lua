local sign
sign = require("ltypekit").sign
local die, warn, dieif
do
  local _obj_0 = require("lbuilder.util")
  die, warn, dieif = _obj_0.die, _obj_0.warn, _obj_0.dieif
end
local typeof, typeforall
do
  local _obj_0 = require("ltypekit.type")
  typeof, typeforall = _obj_0.typeof, _obj_0.typeforall
end
local ts = (require("tableshape")).types
local pcre
if not pcall(function()
  pcre = require("rex_pcre")
end) then
  pcre = false
end
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
local exclude_string = [[\\["'](*SKIP)(?!)|["'](?:\\["']|[^"'])*["'](*SKIP)(?!)|]]
local expand = sign("Macro -> table -> string -> [MacroError|string]")
expand(function(macro)
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
      local _exp_0 = typeof(macro.condition)
      if "string" == _exp_0 then
        if macro.condition:match("^@") then
          if not (pcre) then
            MacroError("lrexlib-pcre not found")
          end
          macro.condition = macro.condition:sub(2)
          local regex
          if macro.condition:match("^!") then
            macro.condition = macro.condition:sub(2)
            regex = pcre.new(exclude_string .. macro.condition)
          else
            regex = pcre.new(macro.condition)
          end
          if not ((regex:match(input))) then
            MacroError("pcre condition not matched")
          end
        else
          if not ((input:match(macro.condition))) then
            MacroError("condition not matched")
          end
        end
      elseif "table" == _exp_0 then
        local _list_0 = macro.condition
        for _index_0 = 1, #_list_0 do
          local cond = _list_0[_index_0]
          if cond[1] == "pattern" then
            if not ((input:match(cond[2]))) then
              MacroError("condition not matched")
            end
          elseif cond[1] == "peek" then
            if not ((peek() == cond[2])) then
              MacroError("unexpected value in stack")
            end
          elseif cond[1] == "pcre" then
            if not (pcre) then
              MacroError("lrexlib-pcre not found")
            end
            local regex
            if cond[3] then
              regex = pcre.new(exclude_string .. cond[2])
            else
              regex = pcre.new(cond[2])
            end
            if not ((regex:match(input))) then
              MacroError("pcre condition not matched")
            end
          else
            MacroError("unknown condition type")
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
        if macro.capture[i]:match("^@") then
          if not (pcre) then
            MacroError("lrexlib-pcre not found")
          end
          macro.capture[i] = macro.capture[i]:sub(2)
          local regex_capture
          if macro.capture[i]:match("^!") then
            macro.capture[i] = macro.capture[i]:sub(2)
            regex_capture = pcre.new(exclude_string .. macro.capture[i])
          else
            regex_capture = pcre.new(macro.capture[i])
          end
          input = pcre.gsub(input, regex_capture, macro.replace[i])
        else
          input = input:gsub(macro.capture[i], macro.replace[i])
        end
      end
      if macro.stack then
        local _list_0 = macro.stack
        for _index_0 = 1, #_list_0 do
          local oper = _list_0[_index_0]
          if oper[1] == "push" then
            push(oper[2])
          elseif oper[1] == "pop" then
            if not ((pop() == oper[2])) then
              MacroError("unexpected value in stack after replacements")
            end
          end
        end
      end
      return input, stack
    end
  end
end)
local expand_many = sign("table -> table -> string -> [MacroError|string]")
expand_many(function(macrol)
  do
    local type = typeforall(macrol)
    if type then
      dieif(SIG, (type ~= "Macro"), "Unexpected type at 'expand_many'. Expected Macro, got " .. tostring(type))
    else
      MacroError("unexpected type in 'expand_many'")
    end
  end
  return function(stack)
    return function(input)
      for name, macro in pairs(macrol) do
        input, stack = expand(macro, stack, input)
      end
      return input, stack
    end
  end
end)
return {
  Macro = Macro,
  MacroError = MacroError,
  expand = expand,
  expand_many = expand_many
}
