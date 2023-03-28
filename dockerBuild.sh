#!/bin/bash

version=0.2

# Better at the beginning
echo "DockerHub password"
docker login --username=francistor || exit 1

# Generate docker image
docker build --file Dockerfile --build-arg version=$version --tag radius2elasticsearch:$version .

# Publish to docker hub
docker tag radius2elasticsearch:$version francistor/radius2elasticsearch:$version
docker push francistor/radius2elasticsearch:$version

# Execute inine and delete 
# docker run --rm -it -p 21812:21812 -p 21813:21813 -p 28080:28080 --name radius2elasticsearch francistor/radius2elasticsearch:0.2

# Execute detached
# docker run --name radius2elasticsearch -p 21812:21812 -p 21813:21813 -p 28080:28080 -d francistor/radius2elasticsearch:0.2
