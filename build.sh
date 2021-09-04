#!/usr/bin/env sh
echo "building pdf"
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md --lua-filter=newpage.lua -H header.tex --template template.tex -t pdf > cv.pdf
echo "building plain markdown"
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md --lua-filter=newpage.lua -t markdown_mmd > plaincv.md
echo "building html"
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md --lua-filter=newpage.lua -t html -s --css my.css > cv.html
