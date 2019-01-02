import Text.Parsec.Prim (regularParse)
import Text.Parsec.Char (char)

main = regularParse (char "x") "xyz"
