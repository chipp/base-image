.DEFAULT_GOAL := push

build:
	docker build . -t docker.pkg.github.com/chipp/base-image/build-rust:latest

push: build
	docker push docker.pkg.github.com/chipp/base-image/build-rust:latest
