local sign
sign = require("ltypekit").sign
local sanitize = sign("string -> string")
sanitize(function(pattern)
  if pattern then
    return pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
  end
end)
return {
  sanitize = sanitize,
  atomize = atomize
}
