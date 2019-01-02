local sign
sign = require("ltypekit").sign
local typeof, typeforall
do
  local _obj_0 = require("ltypekit.type")
  typeof, typeforall = _obj_0.typeof, _obj_0.typeforall
end
local die, warn, dieif
do
  local _obj_0 = require("lbuilder.util")
  die, warn, dieif = _obj_0.die, _obj_0.warn, _obj_0.dieif
end
local map, foldl
do
  local _obj_0 = require("fun")
  map, foldl = _obj_0.map, _obj_0.foldl
end
local commons = require("lbuilder.commons")
local SIG, Atom, Chain, Composite, Literal, Set
SIG = {
  name = "=(top_level)"
}
local wrap = sign("[Atom|Chain|Composite] -> [string|table] -> boolean")
wrap(function(any)
  return function(value)
    local _exp_0 = typeof(any)
    if "Atom" == _exp_0 or "Composite" == _exp_0 then
      dieif(SIG, ((typeof(value)) ~= "string"), "Wrong typeof for 'wrap' function. Expected string, got " .. tostring(typeof(value)))
      any.pattern = value
    elseif "Chain" == _exp_0 then
      dieif(SIG, ((typeof(value)) ~= "table"), "Wrong typeof for 'wrap' function. Expected table, got " .. tostring(typeof(value)))
      any.chain = value
    end
    return true
  end
end)
local unwrap = sign("[Atom|Chain|Composite] -> [string|table]")
unwrap(function(any)
  local _exp_0 = typeof(any)
  if "Atom" == _exp_0 or "Composite" == _exp_0 then
    return any.pattern
  elseif "Chain" == _exp_0 then
    return any.chain
  end
end)
local saved = { }
local save = sign("[Atom|Chain|Composite] -> boolean")
save(function(any)
  if any then
    saved[any.name] = any
    return true
  else
    return false
  end
end)
local get = sign("string -> [string|table|boolean]")
get(function(name)
  return saved[name] and (saved[name].pattern and saved[name].pattern or saved[name].chain) or false
end)
local whole = sign("string -> [Atom|Chain|Composite|boolean]")
whole(function(name)
  return saved[name] or false
end)
Atom = sign("string, [string?], [string?] -> Atom")
Atom(function(pattern, name, kind)
  if name == nil then
    name = ""
  end
  if kind == nil then
    kind = "normal"
  end
  return setmetatable({
    pattern = pattern,
    name = name,
    kind = kind
  }, {
    __type = "Atom"
  })
end)
Chain = sign("table, [string?] -> Chain")
Chain(function(chain, name)
  if name == nil then
    name = ""
  end
  return setmetatable({
    chain = chain,
    name = name
  }, {
    __type = "Chain"
  })
end)
Composite = sign("Atom, [string?] -> Composite")
Composite(function(atom, name)
  if name == nil then
    name = ""
  end
  return setmetatable({
    pattern = unwrap(atom),
    name = name
  }, {
    __type = "Composite"
  })
end)
Literal = sign("string, [string?], [string?] -> Atom")
Literal(function(text, name, kind)
  if name == nil then
    name = ""
  end
  if kind == nil then
    kind = "literal"
  end
  return Atom((commons.sanitize(text)), name, kind)
end)
Set = sign("string, [boolean?], [string?], [string?] -> Atom")
Set(function(text, negate, name, kind)
  if negate == nil then
    negate = false
  end
  if name == nil then
    name = ""
  end
  if kind == nil then
    kind = "set"
  end
  return Atom(("[" .. tostring(negate and "^" or "") .. text .. "]"), name, kind)
end)
local merge = sign("Chain -> Atom")
merge(function(chain)
  return Atom((foldl((function(m, a)
    return m .. a.pattern
  end), "", chain.chain)), chain.name)
end)
local map_ = sign("Chain, / -> Chain")
map_(function(chain, apply)
  chain.chain = map((function(v)
    return apply(v)
  end), chain.chain)
end)
local join = sign("table -> [Atom|boolean]")
join(function(anyl)
  do
    local type = typeforall(anyl)
    if type then
      local _exp_0 = type
      if "Atom" == _exp_0 or "Composite" == _exp_0 then
        return Atom((foldl((function(memo, elem)
          return memo .. elem.pattern
        end), "", anyl)))
      else
        return die(SIG, "Unexpected type at 'join'. Expected Atom or Composite, got " .. tostring(type))
      end
    else
      return false
    end
  end
end)
local combine = sign("table -> [Atom|boolean]")
combine(function(atoml, name)
  if name == nil then
    name = "anonymous"
  end
  do
    local type = typeforall(atoml)
    if type then
      dieif(SIG, (type ~= "Atom"), "Unexpected type at 'combine'. Expected Atom, got " .. tostring(type))
      for _index_0 = 1, #atoml do
        local atom = atoml[_index_0]
        SIG = {
          name = atom.name,
          pattern = atom.pattern
        }
        dieif(SIG, (atom.kind ~= "set"), "Unexpected kind at 'combine'. Expected 'set', got " .. tostring(atom.kind))
      end
      local atomlp = map(atoml, function(k, v)
        local newv
        if v.pattern:match("^%[^") then
          newv = v.pattern:gsub(3, -2)
        else
          newv = v.pattern:gsub(2, -2)
        end
        return Atom(newv, v.name, v.kind)
      end)
      return Set((foldl((function(memo, atom)
        return memo .. atom.pattern
      end), atomlp[1].pattern, atomlp)), false, name)
    else
      return false
    end
  end
end)
local negate = sign("Atom -> Atom")
negate(function(atom)
  if atom.kind == "set" then
    local pat = unwrap(atom)
    if pat:match("^%[^") then
      return Set((pat:gsub(3, -2)), false, atom.name)
    else
      return Set((pat:gsub(2, -2)), true, atom.name)
    end
  else
    return Set((unwrap(atom)), true, atom.name)
  end
end)
local repeat_ = sign("number, [boolean?] -> Atom -> Atom")
repeat_(function(n, at_most)
  if at_most == nil then
    at_most = false
  end
  if not (number > 0) then
    die("Number must be bigger than 0")
  end
  return function(atom)
    if not at_most then
      return Atom((atom.pattern:rep(n)), atom.name, atom.kind)
    else
      return Atom((atom.pattern:rep(n)) .. (negate(atom)), atom.name, atom.kind)
    end
  end
end)
local attach = sign("table -> [Chain?]")
attach(function(chainl)
  do
    local type = typeforall(chainl)
    if type then
      dieif(SIG, (type ~= "Chain"), "Unexpected type at 'attach'. Expected Chain, got " .. tostring(type))
      return Chain((foldl((function(memo, chain)
        local _list_0 = chain.chain
        for _index_0 = 1, #_list_0 do
          local i, atom = _list_0[_index_0]
          table.insert(memo, atom)
        end
      end), chainl[1].chain, chainl)))
    else
      return false
    end
  end
end)
local pick = sign("Chain, number -> Atom")
pick(function(chain, n)
  return chain.chain[n]
end)
local swap = sign("Chain, number, number -> Chain")
swap(function(chain, fr, to)
  local cfrom = chain.chain[fr]
  local cto = chain.chain[to]
  chain.chain[to] = cfrom
  chain.chain[fr] = cto
  return chain
end)
local transform = sign("Chain, number, / -> Chain")
transform(function(chain, n, apply)
  chain.chain[n] = apply(chain.chain[n])
end)
local optional = sign("Atom -> Atom")
optional(function(atom)
  return Atom((atom.pattern .. "?"), atom.name, atom.kind)
end)
local many = sign("Atom -> Atom")
many(function(atom)
  return Atom((atom.pattern .. "+"), atom.name, atom.kind)
end)
local any = sign("Atom -> Atom")
any(function(atom)
  return Atom((atom.pattern .. "*"), atom.name, atom.kind)
end)
local least = sign("Atom -> Atom")
least(function(atom)
  return Atom((atom.pattern .. "-"), atom.name, atom.kind)
end)
local begin = sign("Atom -> Atom")
begin(function(atom)
  return Atom(("^" .. atom.pattern), atom.name, atom.kind)
end)
local final = sign("Atom -> Atom")
final(function(atom)
  return Atom((atom.pattern .. "$"), atom.name, atom.kind)
end)
local test = sign("Composite -> string -> boolean")
test(function(composite)
  return function(text)
    return (type(text:match((unwrap(composite))))) ~= "nil"
  end
end)
local match = sign("Composite -> string -> table")
match(function(composite)
  return function(text)
    local _accum_0 = { }
    local _len_0 = 1
    for match in text:gmatch((unwrap(composite))) do
      _accum_0[_len_0] = match
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
end)
local count = sign("Composite -> string -> number")
count(function(composite)
  return function(text)
    return select(2, text:gsub((unwrap(composite)), ""))
  end
end)
local gmatch = sign("Composite -> string -> string")
gmatch(function(composite)
  return function(text)
    local matchl = (match(composite))(text)
    local ix = 0
    local limit = #matchl
    return function()
      ix = ix + 1
      if ix <= limit then
        return matchl[ix]
      end
    end
  end
end)
local replace = sign("Composite -> string, [number?] -> [string|function|signed] -> string")
replace = function(composite)
  return function(replacewith, limit)
    return function(text)
      return text:gsub((unwrap(composite)), replacewith, limit)
    end
  end
end
return {
  wrap = wrap,
  unwrap = unwrap,
  save = save,
  get = get,
  whole = whole,
  Atom = Atom,
  Chain = Chain,
  Composite = Composite,
  Literal = Literal,
  Set = Set,
  merge = merge,
  join = join,
  combine = combine,
  map = map_,
  repeat_ = repeat_,
  negate = negate,
  pick = pick,
  attach = attach,
  transform = transform,
  swap = swap,
  optional = optional,
  many = many,
  any = any,
  least = least,
  begin = begin,
  final = final,
  test = test,
  match = match,
  count = count,
  replace = replace,
  gmatch = gmatch
}
