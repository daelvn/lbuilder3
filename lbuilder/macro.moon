--> # lbuilder3/macro
--> Conditional replacements for strings.
--> Mediocre macro expansion.
import sign               from require "ltypekit"
import die, warn, dieif   from require "lbuilder.util"
import typeof, typeforall from require "ltypekit.type"
ts                           = (require "tableshape").types

local pcre
if not pcall ->
    pcre = require "rex_pcre"
  pcre   = false

--> ## Macro
--> Provides a function to create Macros that lbuilder can use.
Macro = sign "string, table -> Macro"
Macro (name, macrot) ->
  macrot.name = name
  setmetatable macrot, {__type: "Macro"}

--> ## MacroError
--> Errors related to parsing
MacroError = sign "string -> MacroError"
MacroError (s) -> setmetatable {
  tracelimit: 5
  message:    s
  extra:      "lbuilder3/macro"
}, { __type: "MacroError" }

--> ## Basic macro structure
--> ```moon
--> example = Macro "@example"   -- Name of the macro
-->   condition:                 -- Can be only a string (pattern), or a table with other conditions.
-->     {"pattern", "xyx"}       -- Checks that the string matches a pattern
-->     {"pcre", "xyx"}          -- PCRE pattern. Uses lrexlib-pcre
-->     {"peek", "x"}            -- Checks that the top item in the stack is x
-->     "@xyx"                   -- Start a pattern with @ to indicate it is pcre
-->     {"pcre", "x", true}      -- Matches only outside strings. Must use shifted replace numbers (%1 -> %2)
-->   capture:                   -- Fetches captures
-->     "x(y)x"
-->     "@xyx"                   -- pcre pattern
-->     "@!xyx"                  -- pcre pattern and not inside string
-->   replace:                   -- Does the replacements
-->     "xx%1"
-->   stack:                     -- Stack operations. Happen after the capture and replace.
-->     {"push", "x"}
-->     {"pop", "x"}
--> ```
shape_Macro = ts.shape
  condition: ts.string + ts.array_of ts.shape { ts.string, ts.string }
  capture: ts.string + ts.array_of ts.string
  replace: ts.string + ts.array_of ts.string
  stack:   (ts.array_of ts.shape { ts.string, ts.string })\is_optional!
  pass:    ts.integer\is_optional!
      
--> ## get_least_length
--> Compares two tables and returns the length of the least long.
get_least_length = sign "table, table -> number"
get_least_length (a, b) -> if #a > #b then #a else #b

--> ## exclude_prefix
--> This PCRE prefix matches whatever comes after it if it's outside a string or in a comment.
exclude_prefix   = [[\\["'](*SKIP)(?!)]]
exclude_prefix ..= [[|["'](?:\\["']]
exclude_prefix ..= [[|[^"'])*["'](*SKIP)(?!)]]
exclude_prefix ..= [[|\-\-.*\n(*SKIP)(?!)]]
exclude_prefix ..= "|"

--> ## expand
--> Expands a macro in the input.
expand = sign "Macro -> table -> string -> [MacroError|string]"
expand (macro) -> (stack) -> (input) ->
  --> Check that our Macro is valid
  --assert shape_Macro macro
  --> Create an operable stack for the macro.
  push  = (v) -> table.insert stack, 1, v
  peek  =     -> stack[1]
  pop   =     -> table.remove stack, 1
  --> First of all, check the condition(s)
  switch typeof macro.condition
    when "string"
      if macro.condition\match "^@"
        unless pcre then MacroError "lrexlib-pcre not found"
        macro.condition = macro.condition\sub 2
        local regex
        if macro.condition\match "^!"
          macro.condition = macro.condition\sub 2
          regex = pcre.new (exclude_prefix .. macro.condition), "m"
        else
          regex = pcre.new macro.condition, "m"
        unless (regex\match input) then MacroError "pcre condition not matched"
      else
        unless (input\match macro.condition) then MacroError "condition not matched"
    when "table"
      for cond in *macro.condition
        if cond[1] == "pattern"
          unless (input\match cond[2]) then MacroError "condition not matched"
        elseif cond[1] == "peek"
          unless (peek! == cond[2]) then MacroError "unexpected value in stack"
        elseif cond[1] == "pcre"
          unless pcre then MacroError "lrexlib-pcre not found"
          local regex
          if cond[3]
            regex = pcre.new (exclude_prefix .. cond[2]), "m"
          else
            regex = pcre.new cond[2], "m"
          unless (regex\match input) then MacroError "pcre condition not matched"
        else
          MacroError "unknown condition type"
  --> Second, we have to get the least length of the tables `capture` & `replace`.
  --> If any of the tables' length is 0, then we should error.
  local ll
  if ((typeof macro.capture) == "table") and ((typeof macro.replace) == "table")
    ll = get_least_length macro.capture, macro.replace
    assert (ll > 0), "cannot have an empty table"
  else
    --> Then, both are strings, so the length is 1.
    ll = 1
    macro.capture = {macro.capture}
    macro.replace = {macro.replace}
  --> Iterate from 1 to `ll` so that we can go over the captures and replaces in order.
  for i=1,ll
    print macro.capture[i], macro.replace[i]
    print ll
    if macro.capture[i]\match "^@"
      unless pcre then MacroError "lrexlib-pcre not found"
      macro.capture[i] = macro.capture[i]\sub 2
      local regex_capture
      if macro.capture[i]\match "^!"
        macro.capture[i] = macro.capture[i]\sub 2
        regex_capture    = pcre.new (exclude_prefix .. macro.capture[i]), "m"
      else
        regex_capture = pcre.new macro.capture[i], "m"
      macro.pass or= 1
      if macro.pass == -1
        input, count = pcre.gsub input, regex_capture, macro.replace[i]
        while count > 0
          input, count = pcre.gsub input, regex_capture, macro.replace[i]
      else
        for j=1,macro.pass
          input, count = pcre.gsub input, regex_capture, macro.replace[i]
    else
      macro.pass or=1
      if macro.pass == -1
        input, count = input\gsub macro.capture[i], macro.replace[i]
        while count > 0
          input, count = input\gsub macro.capture[i], macro.replace[i]
      else
        for j=1,macro.pass
          input, count = input\gsub macro.capture[i], macro.replace[i]

  --> Perform the appropriate stack operations
  if macro.stack
    for oper in *macro.stack
      if oper[1] == "push"
        push oper[2]
      elseif oper[1] == "pop"
        unless (pop! == oper[2]) then MacroError "unexpected value in stack after replacements"
  --> Return the string and the final stack
  return input, stack

--> Export
{ :Macro, :MacroError, :expand }
