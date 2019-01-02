builder = require "lbuilder.builder"
import Atom, Chain, Composite, Literal, Set from builder
import printi from require "ltext"

whitespace = Set " \t"
hello      = Literal "Hello,"
world      = Literal "World!"
full       = builder.join {hello, whitespace, world}
mystring   = "Hello, World!"
cfull      = Composite full
print (builder.test cfull) mystring

chain = Chain {whitespace, hello, world}
chain = builder.swap chain, 1, 2
full  = builder.merge chain
cfull = Composite full
print (builder.test cfull) mystring

printi builder.atomize cfull
