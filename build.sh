#!/usr/bin/env nix-shell
#! nix-shell -i sh -p zlib gcc
echo "building pdf"
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md --lua-filter=newpage.lua -H header.tex --template template.tex -t pdf > cv.pdf
echo "building site"
cabal new-install --overwrite-policy=always
echo "cleaning site"
~/.cabal/bin/site clean
echo "running site watch"
~/.cabal/bin/site watch
