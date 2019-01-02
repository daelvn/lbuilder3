--> # lbuilder3
--> Pattern builder
-- 21.12.2018 (Happy Birthday Joel!)
-- By daelvn
import sign from require "ltypekit"

--> ## String operations
--> ### sanitize
--> Literalizes a pattern
sanitize = sign "string -> string"
sanitize (pattern) -> pattern\gsub "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0" if pattern

{ :sanitize, :atomize }
