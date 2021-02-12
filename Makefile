.DEFAULT_GOAL := push

build:
	docker build . -t ghcr.io/chipp/build.rust.x86_64.musl:latest

push: build
	docker push ghcr.io/chipp/build.rust.x86_64.musl:latest
