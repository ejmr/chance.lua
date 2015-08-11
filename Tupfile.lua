local sources = {"chance.lua"}

tup.rule(sources, "^ Checking for Warnings and Errors^ luacheck %f")
tup.rule({"chance.spec.lua"}, "^ Running Test Suite^ busted -o plainTerminal --repeat=100 %f > /tmp/chance-busted.log")
tup.rule(sources, "^ Creating TAGS^ ctags-exuberant -e --languages=lua %f", {"TAGS"})
tup.rule(sources, "^ Creating Documentation^ ldoc %f", {"doc/index.html", "doc/ldoc.css"})
