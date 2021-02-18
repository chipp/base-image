.DEFAULT_GOAL := push

alpine:
	docker build . -f Dockerfile.x86_64_musl -t ghcr.io/chipp/build.rust.x86_64_musl:latest

pi:
	docker build . -f Dockerfile.armv7_gnueabihf -t ghcr.io/chipp/build.rust.armv7_gnueabihf:latest

build: alpine pi

push: build
	docker push ghcr.io/chipp/build.rust.x86_64_musl:latest
	docker push ghcr.io/chipp/build.rust.armv7_gnueabihf:latest
