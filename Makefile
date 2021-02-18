.DEFAULT_GOAL := push

alpine:
	docker build . -f Dockerfile.x86_64-musl -t ghcr.io/chipp/build.rust.x86_64.musl:latest

pi:
	docker build . -f Dockerfile.armv7-gnueabihf -t ghcr.io/chipp/build.rust.armv7.gnueabihf:latest

build: alpine pi

push: build
	docker push ghcr.io/chipp/build.rust.x86_64.musl:latest
	docker push ghcr.io/chipp/build.rust.armv7.gnueabihf:latest
