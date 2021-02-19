.DEFAULT_GOAL := push

x86_64:
	docker build . --build-arg TARGET=x86_64-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-x86_64 -t ghcr.io/chipp/build.rust.x86_64_musl:latest

armv7:
	docker build . --build-arg TARGET=armv7-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-generic32 -t ghcr.io/chipp/build.rust.armv7_musl:latest

build: x86_64 armv7

push: build
	docker push ghcr.io/chipp/build.rust.x86_64_musl:latest
	docker push ghcr.io/chipp/build.rust.armv7_musl:latest
