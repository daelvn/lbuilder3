--> # lbuilder3
--> Pattern builder
-- 23.11.2018
-- By daelvn
color = (require "ansicolors") or ((x) -> x\gsub "%b{}","")

warn  = (s) -> print color "%{yellow}[WARN]  #{s}"
panic = (s) -> print color "%{red}[ERROR] #{s}"

traceback = (s) =>
  infot = {}
  for i=1,4 do infot[i] = debug.getinfo i
  print color   "%{red}[lbuilder] #{s}"
  print color   "           In function: %{yellow}#{infot[3].name}"
  print color   "           In pattern:  %{yellow}#{@name or "anonymous"}"
  print color   "           With pattern: %{green}'#{@pattern or "???"}'"
  print color   "           Stack traceback:"
  for i=1,4
    print color "             %{red}#{infot[i].name}%{white} in #{infot[i].source} at line #{infot[i].currentline}"

die = (s) =>
  traceback @, s
  error!

dieif = (cond, s) => die @, s if cond

contains = (t, value) -> for val in *t do if val == value then return true

{ :warn, :panic, :die, :contains, :dieif, :traceback }
