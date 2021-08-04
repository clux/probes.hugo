HUGO_VERSION=0.87.0-ubuntu-onbuild

serve:
	docker run --rm -it --name hugoprobes \
		-p 8080:8080 \
		-v $(shell pwd):/src \
		klakegg/hugo:$(HUGO_VERSION) \
		server -w -p 8080

build:
	docker run --rm -it --name hugoprobes -v $(shell pwd):/src \
		klakegg/hugo:$(HUGO_VERSION)
