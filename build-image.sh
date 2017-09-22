#!/usr/bin/env bash

docker build -t bytepixie/actordb:latest -t bytepixie/actordb:0.10.25-2 `dirname $0`/build/
docker build -t bytepixie/actordb-rancher:latest -t bytepixie/actordb-rancher:0.10.25-2 `dirname $0`/build/rancher/
