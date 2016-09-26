#!/usr/bin/env bash

cd `dirname $0`

#
# Just run ActorDB service(s) in detached mode.
#
docker-compose up -d ### actordb
