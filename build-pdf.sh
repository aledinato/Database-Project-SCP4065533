#!/bin/bash
pandoc bozza.md -o report.pdf --pdf-engine=xelatex -V geometry:margin=0.80in --toc --toc-depth 3 --number-sections --highlight-style=tango