#!/bin/bash

initdb() {
cat > /tmp/init.sql <<EOF
use config
insert into groups values ('${ACTORDB_GROUP}','cluster')
insert into nodes values ('${ACTORDB_NODE}','${ACTORDB_GROUP}')
create user '${ACTORDB_ADMIN_USER}' identified by '${ACTORDB_ADMIN_PASSWORD}'
commit
EOF

log "info" "Initialising node, \"user_exists\" error expected if already initialised."
actordb_console -u ${ACTORDB_ADMIN_USER} -pw ${ACTORDB_ADMIN_PASSWORD} -f /tmp/init.sql
###rm /tmp/init.sql
}

updatedb() {
cat > /tmp/init.sql <<EOF
use config
insert into nodes values ('${ACTORDB_NODE}','${ACTORDB_GROUP}')
commit
EOF

log "info" "Joining cluster, \"insert_on_existing_node\" error expected if already joined."
actordb_console -u ${ACTORDB_ADMIN_USER} -pw ${ACTORDB_ADMIN_PASSWORD} -f /tmp/init.sql ${LEADER_ADDR}
###rm /tmp/init.sql
}

init_or_join() {
	log "info" "Looking for lead container to join..."

	LEADER_CREATE_INDEX=${NODE_CREATE_INDEX}
	LEADER_NAME=${NODE_NAME}

	SIBLINGS=`curl -s 'http://rancher-metadata/2015-12-19/self/service/containers' | cut -d= -f1`
	for index in ${SIBLINGS}
	do
		SIBLING_CREATE_INDEX=`curl -s "http://rancher-metadata/2015-12-19/self/service/containers/${index}/create_index"`
		SIBLING_STATE=`curl -s "http://rancher-metadata/2015-12-19/self/service/containers/${index}/state"`

		log "info" "Sibling Create Index = ${SIBLING_CREATE_INDEX}."
		log "info" "Sibling State = ${SIBLING_STATE}."

		if [ \( "${SIBLING_STATE}" = "running" -o "${SIBLING_STATE}" = "starting" \) -a ${SIBLING_CREATE_INDEX} -lt ${LEADER_CREATE_INDEX} ]
		then
			LEADER_CREATE_INDEX=${SIBLING_CREATE_INDEX}
			LEADER_NAME=`curl -s "http://rancher-metadata/2015-12-19/self/service/containers/${index}/name"`

			log "info" "New Leader Name = ${LEADER_NAME}."
		fi
	done

	log "info" "Final Leader Name = ${LEADER_NAME}."

	if [ "${LEADER_NAME}" = "${NODE_NAME}" ]
	then
		log "info" "I'm the lead container."
		initdb
	else
		LEADER_ADDR="${LEADER_NAME}.${NODE_DOMAIN}"
		log "info" "I'm not the lead container, joining ${LEADER_NAME} in ${MAX_WAIT} seconds..."
		sleep ${MAX_WAIT}
		updatedb
	fi
}

#
# Get current container's "number" and name.
NODE_CREATE_INDEX=`curl -s 'http://rancher-metadata/2015-12-19/self/container/create_index'`
NODE_INDEX=`curl -s 'http://rancher-metadata/2015-12-19/self/container/service_index'`
NODE_NAME=`curl -s 'http://rancher-metadata/2015-12-19/self/container/name'`
NODE_DOMAIN="rancher.internal"

#
# Override node name.
ACTORDB_NODE="node${NODE_INDEX}@${NODE_NAME}.${NODE_DOMAIN}"

#
# Run server config with overridden ACTORDB_NODE.
. /docker-config.sh

#
# Start local node.
/docker-run.sh &

#
# Wait between 1 to 10 seconds in the hope that at least one container "wins" and becomes the leader when they all start at the same time.
MAX_WAIT=10
WAIT_TIME=$(( ( RANDOM % ${MAX_WAIT} )  + 1 ))
log "info" "Waiting for ${WAIT_TIME} seconds before attempting to start..."
sleep ${WAIT_TIME}
log "info" "...starting up."

init_or_join

unset ACTORDB_ADMIN_USER ACTORDB_ADMIN_PASSWORD ACTORDB_GROUP ACTORDB_SCALE ACTORDB_THRIFT_PORT ACTORDB_MYSQL_PORT VOLUME_DRIVER HOST_LABEL

wait

log "warn" "Background actordb process finished, shutting down node."
