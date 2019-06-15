# https://github.com/jgm/pandoc/wiki/Using-pandoc-to-produce-reveal.js-slides

INPUT := $(shell ls slide*.md | head -n1)
OUTPUT := $(INPUT:.md=.html)
REVEAL_JS_URL := https://revealjs.com

THEME ?= league

# beige
# black
# blood
# league
# moon
# night
# serif
# simple
# sky
# solarized
# white

slides:
	@date
	pandoc -t revealjs \
		-s -o $(OUTPUT) \
		--toc \
		--toc-depth=3 \
		$(INPUT) \
		-V revealjs-url=$(REVEAL_JS_URL) \
		-V theme=$(THEME)

open: slides
	open $(OUTPUT)

watch:
	watchmedo shell-command -p '*.md;Makefile' -c 'make slides'
