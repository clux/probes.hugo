HUGO := "klakegg/hugo:0.87.0-ubuntu-onbuild"

default:
  @just --list --unsorted --color=always | rg -v "    default"

serve:
  docker run --rm -it --name hugo -p 8080:8080 -v $PWD:/src {{HUGO}} server -w -p 8080

build:
  docker run --rm -it --name hugo -v $PWD:/src {{HUGO}}

# mode: makefile
# End:
# vim: set ft=make :
