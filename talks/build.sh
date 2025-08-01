pandoc -t revealjs -s -o scala3.html scala3.md --slide-level=2
pandoc -t revealjs -s -o tdd.html tdd.md --slide-level=3 --lua-filter=graphviz-filter.lua
pandoc -t revealjs -s -o graphs.html graphs.md --slide-level=3 --lua-filter=graphviz-filter.lua -V revealjs-url=https://cdn.jsdelivr.net/npm/reveal.js@4.4.0
