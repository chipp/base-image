.DEFAULT_GOAL := push

build:
	docker build . -t chippcheg/build.rust:latest

push: build
	docker push chippcheg/build.rust:latest
