#!/usr/bin/env nix-shell
#! nix-shell -i zsh shell.nix
echo "fetching mdoc deps"
CATS_CORE_213=$(cs fetch -p org.typelevel:cats-core_2.13:2.9.0)
SCODEC_CORE_213=$(cs fetch -p org.scodec:scodec-core_2.13:1.11.10)
SQUANTS_213=$(cs fetch -p org.typelevel:squants_2.13:1.8.3)
echo "building mdoc pages"
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$SCODEC_CORE_213:$SQUANTS_213 --in ./mdoc-posts/2023-03-28-count-distinct-at-scale-I.md --out ./posts/ 
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$SCODEC_CORE_213:$SQUANTS_213 --in ./mdoc-posts/2023-03-30-count-distinct-at-scale-II.md --out ./posts/
