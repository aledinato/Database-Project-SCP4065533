#!/bin/bash
pandoc bozza.md -o output.pdf --pdf-engine=xelatex -V geometry:margin=1in --toc --toc-depth 3 --number-sections