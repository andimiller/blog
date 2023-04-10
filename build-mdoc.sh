#!/usr/bin/env nix-shell
#! nix-shell -i zsh shell.nix
echo "fetching mdoc deps"
CATS_CORE_213=$(cs fetch -p org.typelevel:cats-core_2.13:2.9.0)
SCODEC_CORE_213=$(cs fetch -p org.scodec:scodec-core_2.13:1.11.10)
SQUANTS_213=$(cs fetch -p org.typelevel:squants_2.13:1.8.3)
HEDGEHOGS_213=$(cs fetch -p net.andimiller:hedgehogs-core_2.13:0.2.0)
HEDGEHOGS_CIRCE_213=$(cs fetch -p net.andimiller:hedgehogs-circe_2.13:0.2.0)
FS2_IO_213=$(cs fetch -p co.fs2:fs2-io_2.13:3.2.7)
CIRCE_PARSER_213=$(cs fetch -p io.circe:circe-parser_2.13:0.14.1)
echo "building mdoc pages"
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$SCODEC_CORE_213:$SQUANTS_213 --in ./mdoc-posts/2023-03-28-count-distinct-at-scale-I.md --out ./posts/ 
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$SCODEC_CORE_213:$SQUANTS_213 --in ./mdoc-posts/2023-03-30-count-distinct-at-scale-II.md --out ./posts/
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$HEDGEHOGS_213:$HEDGEHOGS_CIRCE_213:$FS2_IO_213:$CIRCE_PARSER_213 --in ./mdoc-posts/2023-04-03-introducing-hedgehogs.md --out ./posts/
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$HEDGEHOGS_213:$HEDGEHOGS_CIRCE_213:$FS2_IO_213:$CIRCE_PARSER_213 --in ./mdoc-posts/2023-04-05-conways-game-of-life-graph.md --out ./posts/
cs launch org.scalameta:mdoc_2.13:2.3.7 -- --classpath $CATS_CORE_213:$HEDGEHOGS_213:$HEDGEHOGS_CIRCE_213:$FS2_IO_213:$CIRCE_PARSER_213 --in ./mdoc-posts/2023-04-09-conways-game-of-life-3d-graph.md --watch --out ./posts/
