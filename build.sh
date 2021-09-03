#!/usr/bin/env sh
pandoc -f markdown+pipe_tables+yaml_metadata_block cv.md -H header.tex --template template.tex -t pdf > cv.pdf
