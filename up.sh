#!/usr/bin/env bash

cd `dirname $0`

#
# When running on some systems node*/data and node*/logs permissions need to be opened up for write.
#
chmod go+rwx node*/data
chmod go+rwx node*/logs

#
# Just run ActorDB service(s) in detached mode.
#
docker-compose up -d ### actordb
