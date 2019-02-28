#!/bin/bash -e

version=$1

if [ -z "$version" ]; then
    echo "docker-release.sh <version>"
    exit 1
fi

docker build . \
    -t calid/zmq-ffi-testenv:$version \
    -t calid/zmq-ffi-testenv:latest \
    -t calid/zmq-ffi-testenv:ubuntu

for t in $version latest ubuntu; do
    docker push calid/zmq-ffi-testenv:$t
done
