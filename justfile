HUGO := "klakegg/hugo:0.105.0-ubuntu-onbuild"
open := if os() == "macos" { "open" } else { "xdg-open" }

[private]
default:
  @just --list --unsorted

serve:
  (sleep 2 && {{open}} http://127.0.0.1:8080/) &
  docker run --rm -it --name hugo -p 8080:8080 -v $PWD:/src {{HUGO}} server -w -p 8080

build:
  docker run --rm -it --name hugo -v $PWD:/src {{HUGO}}
