--> # lbuilder3 - Usage
--> Specification file for lbuilder3. The plan is to start completely from scratch, to avoid copying logic bugs.

--> Basic structure
Atom -> Chain{Atom} -> Atom
     -> Composite
Atom == Literal
     == Set

--> tinyparse
a    = Atom "a"
b    = Atom "b"
aorb = tinyparse.or a, b
tinyparse.match aorb
