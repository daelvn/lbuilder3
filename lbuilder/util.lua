local color = (require("ansicolors")) or (function(x)
  return x:gsub("%b{}", "")
end)
local warn
warn = function(s)
  return print(color("%{yellow}[WARN]  " .. tostring(s)))
end
local panic
panic = function(s)
  return print(color("%{red}[ERROR] " .. tostring(s)))
end
local traceback
traceback = function(self, s)
  local infot = { }
  for i = 1, 4 do
    infot[i] = debug.getinfo(i)
  end
  print(color("%{red}[lbuilder] " .. tostring(s)))
  print(color("           In function: %{yellow}" .. tostring(infot[3].name)))
  print(color("           In pattern:  %{yellow}" .. tostring(self.name or "anonymous")))
  print(color("           With pattern: %{green}'" .. tostring(self.pattern or "???") .. "'"))
  print(color("           Stack traceback:"))
  for i = 1, 4 do
    print(color("             %{red}" .. tostring(infot[i].name) .. "%{white} in " .. tostring(infot[i].source) .. " at line " .. tostring(infot[i].currentline)))
  end
end
local die
die = function(self, s)
  traceback(self, s)
  return error()
end
local dieif
dieif = function(self, cond, s)
  if cond then
    return die(self, s)
  end
end
local contains
contains = function(t, value)
  for _index_0 = 1, #t do
    local val = t[_index_0]
    if val == value then
      return true
    end
  end
end
return {
  warn = warn,
  panic = panic,
  die = die,
  contains = contains,
  dieif = dieif,
  traceback = traceback
}
