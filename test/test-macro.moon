-- for now let's work with :: and .=
import Macro, expand from require "lbuilder.macro"

id = "[a-zA-Z_][a-zA-Z0-9_]*"

macros      = {}
macros.sign = Macro "msmx/sign"
  condition: "@!#{id} ?:: ?.+"
  capture:   "@!(#{id}) ?:: ?(.+)"
  replace:   [[%1 = sign "%2"]]

macros.apply = Macro "msmx/operator:update-apply"
  condition: "#{id} ?.= ?#{id}"
  capture:   "(#{id}) ?.= ?(#{id})"
  replace:   "%1 = %2 %1"

code_forsign  = "f :: string -> table"
code_forapply = "x .= f"

x1 = ((expand macros.sign) {}) code_forsign
x2 = ((expand macros.apply) {}) code_forapply

print x1
print x2
