#!/usr/bin/env bash

cd `dirname $0`

#
# Display and follow logs.
#
docker-compose logs -f
