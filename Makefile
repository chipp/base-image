.DEFAULT_GOAL := push

x86_64:
	docker build . --build-arg TARGET=x86_64-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-x86_64 -t ghcr.io/chipp/build.rust.x86_64_musl:latest

armv7:
	docker build . --build-arg TARGET=armv7-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-generic32 -t ghcr.io/chipp/build.rust.armv7_musl:latest

build: x86_64 armv7

tag: RUST_VERSION=$(shell cat Dockerfile | grep "ENV RUST_VERSION" | sed -e 's,ENV RUST_VERSION=\(.*\),\1,' | tr -d '\n')
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(RUST_VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(RUST_VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(RUST_VERSION)_$(NEXT_REVISION)
