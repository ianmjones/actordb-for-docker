#!/usr/bin/env bash

docker build -t bytepixie/actordb:latest -t bytepixie/actordb:0.10.24 `dirname $0`/build/
