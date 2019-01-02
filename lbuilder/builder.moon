--> # lbuilder3
--> Pattern builder
-- 20.12.2018
-- By daelvn
import sign               from require "ltypekit"
import typeof, typeforall from require "ltypekit.type"
import die, warn, dieif   from require "lbuilder.util"
import map, foldl         from require "fun"
commons                      = require "lbuilder.commons"
--> Forward declare all locals with capital names (Atom, Chain...)
local ^

--> SIG preset to ensure nil is not passed
SIG = { name: "=(top_level)" }

--> ## wrap
--> Sets the value for an element (Any of Atom, Chain or Composite).
--> In the case of Chain, it will use the value as a whole table.
wrap = sign "[Atom|Chain|Composite] -> [string|table] -> boolean"
wrap (any) -> (value) ->
  switch typeof any
    when "Atom", "Composite"
      dieif SIG, ((typeof value) != "string"), "Wrong typeof for 'wrap' function. Expected string, got #{typeof value}"
      any.pattern = value
    when "Chain"
      dieif SIG, ((typeof value) != "table"), "Wrong typeof for 'wrap' function. Expected table, got #{typeof value}"
      any.chain = value
  true

--> ## unwrap
--> The opposite of [wrap](#wrap). Returns the value for any.
unwrap = sign "[Atom|Chain|Composite] -> [string|table]"
unwrap (any) ->
  switch typeof any
    when "Atom", "Composite" then any.pattern
    when "Chain"             then any.chain

-- Saves table
saved = {}

--> ## save
--> Saves any element by its name in the module's `saved` table
save = sign "[Atom|Chain|Composite] -> boolean"
save (any) ->
  if any
    saved[any.name] = any
    true
  else
    false

--> ## get
--> Returns the value (pattern or chain) of an element in the `saves` table
get = sign "string -> [string|table|boolean]"
get (name) -> saved[name] and (saved[name].pattern and saved[name].pattern or saved[name].chain) or false

--> ## whole
--> Returns the full object by a name.
whole = sign "string -> [Atom|Chain|Composite|boolean]"
whole (name) -> saved[name] or false

--> ## Atom
--> The most basic structure of lbuilder. It contains a single pattern that can be modified according to
--> the functions in the object.
Atom = sign "string, [string?], [string?] -> Atom"
Atom (pattern, name="", kind="normal") -> setmetatable {
  --> Base of the object
  :pattern
  :name
  :kind
}, { __type: "Atom" }

--> ## Chain
--> Chain of [Atoms](#Atom) that can be ordered. Can be recompiled into an Atom. It takes a lists of Atoms
--> as the initializer. Can take a name as well.
Chain = sign "table, [string?] -> Chain"
Chain (chain, name="") -> setmetatable {
  --> Base of the object
  :chain -- atoml
  :name
}, { __type: "Chain" }

--> ## Composite
--> Compiled version of an [Atom](#Atom) that can return values. Practically not different
--> from an Atom, but with different methods and metamethods. Uses [unwrap](#unwrap) to extract
--> the value from the passed element.
Composite = sign "Atom, [string?] -> Composite"
Composite (atom, name="") -> setmetatable {
  --> Base of the object
  pattern: unwrap atom
  :name
}, { __type: "Composite" }

--> ## Literal
--> Creates a literal [Atom](#Atom). Escapes everything pattern-related in the passsed string.
Literal = sign "string, [string?], [string?] -> Atom"
Literal (text, name="", kind="literal") -> Atom (commons.sanitize text), name, kind

--> ## Set
--> Creates a set based on [Atom](#Atom) that can be negated and such. The passed string
--> is automatically surrounded in quotes. You can pass negate=true (2nd argument) to
--> Create a negated pattern.
Set = sign "string, [boolean?], [string?], [string?] -> Atom"
Set (text, negate=false, name="", kind="set") -> Atom ("[#{negate and "^" or ""}"..text.."]"), name, kind

--> ## compose
--> Turns an Atom into a [Composite](#Composite) object. This function is actually not of much use, hence it's commented.
--> You can just use the Composite builder.
--compose = sign "Atom -> Composite"
--compose (atom) -> Composite atom

--> ## merge
--> Turns a [Chain](#Chain] into a single [Atom](#Atom).
merge = sign "Chain -> Atom"
merge (chain) -> Atom (foldl ((m,a) -> m .. a.pattern), "", chain.chain), chain.name

--> ## map
--> Uses a predicate on every item in the chain.
map_ = sign "Chain, / -> Chain"
map_ (chain, apply) -> chain.chain = map ((v) -> apply v), chain.chain

--> ## join
--> Joins several elements, usually by concatenating them. In the case of sets, use [combine](#combine).
--> This function does not mutate the original elements, so it returns a new [Atom](#atom). If you want to mutate
--> the original object, you can do so simply:
--> ```moon
--> any = join {any, b, c}
--> ```
--> Note that all elements must be of the same type.
join = sign "table -> [Atom|boolean]"
join (anyl) ->
  if type = typeforall anyl
    switch type
      when "Atom", "Composite"
        Atom (foldl ((memo, elem) -> memo .. elem.pattern), "", anyl)
      else
        die SIG, "Unexpected type at 'join'. Expected Atom or Composite, got #{type}"
  else false

--> ## combine
--> Combines several sets together
combine = sign "table -> [Atom|boolean]"
combine (atoml, name="anonymous") ->
  if type = typeforall atoml
    dieif SIG, (type != "Atom"), "Unexpected type at 'combine'. Expected Atom, got #{type}"
    for atom in *atoml
      SIG = {name: atom.name, pattern: atom.pattern}
      dieif SIG, (atom.kind != "set"), "Unexpected kind at 'combine'. Expected 'set', got #{atom.kind}"
    atomlp = map atoml, (k, v) ->
      local newv
      if v.pattern\match "^%[^" then newv = v.pattern\gsub 3,-2
      else                           newv = v.pattern\gsub 2,-2
      Atom newv, v.name, v.kind
    Set (foldl ((memo, atom) -> memo .. atom.pattern), atomlp[1].pattern, atomlp), false, name
  else false

--> ## negate
--> Creates a new and negated atom. Output type is always Atom>Set.
negate = sign "Atom -> Atom"
negate (atom) ->
  if atom.kind == "set"
    pat = unwrap atom
    if pat\match "^%[^"
      Set (pat\gsub 3,-2), false, atom.name
    else
      Set (pat\gsub 2,-2), true, atom.name
  else
    Set (unwrap atom), true, atom.name

--> ## repeat
--> Repeats a pattern n times at least or at most. When used partially, it serves as a [map](#map) predicate.
--> It does not mutate the original atom.
repeat_ = sign "number, [boolean?] -> Atom -> Atom"
repeat_ (n, at_most=false) ->
  if not (number > 0) then die "Number must be bigger than 0"
  (atom) ->
    if not at_most
      Atom (atom.pattern\rep n), atom.name, atom.kind
    else
      Atom (atom.pattern\rep n) .. (negate atom), atom.name, atom.kind

--> ## attach
--> Joins several chains together. Creates a new Chain.
attach = sign "table -> [Chain?]"
attach (chainl) ->
  if type = typeforall chainl
    dieif SIG, (type != "Chain"), "Unexpected type at 'attach'. Expected Chain, got #{type}"
    Chain (foldl ((memo, chain) ->
      for i, atom in *chain.chain
        table.insert memo, atom
    ), chainl[1].chain, chainl)
  else false

--> ## pick
--> Picks out a specific index from a chain.
pick = sign "Chain, number -> Atom"
pick (chain, n) -> chain.chain[n]

--> ## swap
--> Swaps two indexes in a chain
swap = sign "Chain, number, number -> Chain"
swap (chain, fr, to) ->
  cfrom = chain.chain[fr]
  cto   = chain.chain[to]
  chain.chain[to] = cfrom
  chain.chain[fr] = cto
  chain

--> ## transform
--> Applies a function to an Atom at index n of a Chain.
transform = sign "Chain, number, / -> Chain"
transform (chain, n, apply) -> chain.chain[n] = apply chain.chain[n]

--> ## optional
--> Makes an Atom optional. Does not mutate the Atom. Can be used as predicate.
optional = sign "Atom -> Atom"
optional (atom) -> Atom (atom.pattern.."?"), atom.name, atom.kind

--> ## many
--> Uses the + modifier on an Atom. Creates a new Atom. Can be used as predicate.
many = sign "Atom -> Atom"
many (atom) -> Atom (atom.pattern.."+"), atom.name, atom.kind

--> ## any
--> Uses * on an Atom. Doesn't mutate the Atom. Can be used as predicate.
any = sign "Atom -> Atom"
any (atom) -> Atom (atom.pattern.."*"), atom.name, atom.kind

--> ## least
--> Uses the - operator on an Atom. Does not mutate the Atom. Can be used as predicate.
least = sign "Atom -> Atom"
least (atom) -> Atom (atom.pattern.."-"), atom.name, atom.kind

--> ## begin
--> Place a beginning marker ^ on the Atom. Creates a new Atom. Can be used as a predicate as well.
begin = sign "Atom -> Atom"
begin (atom) -> Atom ("^"..atom.pattern), atom.name, atom.kind

--> ## final
--> Place a final marker $ on the Atom. Creates a new Atom. Can be used as a predicate as well.
final = sign "Atom -> Atom"
final (atom) -> Atom (atom.pattern.."$"), atom.name, atom.kind

--> ## test
--> Checks whether a Composite would work on a string.
test = sign "Composite -> string -> boolean"
test (composite) -> (text) -> (type text\match (unwrap composite)) != "nil"

--> ## match
--> Returns a table of the matches of Composite for a string.
match = sign "Composite -> string -> table"
match (composite) -> (text) -> [match for match in text\gmatch (unwrap composite)]

--> ## count
--> Returns a count of the matches of Composite for a string.
count = sign "Composite -> string -> number"
count (composite) -> (text) -> select 2, text\gsub (unwrap composite), ""

--> ## gmatch
--> Iterator that returns each of the matches of Composite for a string
gmatch = sign "Composite -> string -> string"
gmatch (composite) -> (text) ->
  matchl = (match composite) text
  ix     = 0
  limit  = #matchl
  ->
    ix += 1
    if ix <= limit then matchl[ix]

--> ## replace
--> Replace Composite by replacewith in string. You can optionally set a limit.
replace = sign "Composite -> string, [number?] -> [string|function|signed] -> string"
replace = (composite) -> (replacewith, limit) -> (text) -> text\gsub (unwrap composite), replacewith, limit


{
  :wrap, :unwrap
  :save, :get, :whole
  :Atom, :Chain, :Composite
  :Literal, :Set
  :merge, :join, :combine
  map: map_
  :repeat_, :negate
  :pick, :attach, :transform, :swap
  :optional, :many, :any, :least, :begin, :final
  :test, :match, :count, :replace, :gmatch
}
