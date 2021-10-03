pandoc -t revealjs -s -o scala3.html scala3.md --slide-level=2
pandoc -t revealjs -s -o tdd.html tdd.md --slide-level=3 --lua-filter=graphviz-filter.lua
