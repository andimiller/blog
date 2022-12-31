#!/usr/bin/env nix-shell
#! nix-shell -i sh -p zlib gcc haskellPackages.pandoc haskellPackages.cabal-install ghc pkg-config
echo "building pdf"
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md --lua-filter=newpage.lua -H header.tex --template template.tex -t pdf > cv.pdf
echo "updating cabal"
cabal update
echo "building site"
cabal new-install --overwrite-policy=always
echo "cleaning site"
~/.cabal/bin/site clean
echo "running site build"
~/.cabal/bin/site build
echo "making github-pages tarball"
tar czvf github-pages.tar.gz -C _site .
