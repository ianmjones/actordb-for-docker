#!/bin/sh -eu

#
# Variables
#
ACTORDB_USER=actordb
ACTORDB_GROUP=actordb
ACTORDB_UID=`id -u ${ACTORDB_USER}`
ACTORDB_GID=`id -g ${ACTORDB_GROUP}`
DEBUG_COMMANDS=0

#
# Functions
#
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

# Test if argument is an integer.
#
# @param  mixed
# @return integer	0: is int | 1: not an int
isint() {
	echo "${1}" | grep -Eq '^([0-9]|[1-9][0-9]*)$'
}


################################################################################
# MAIN ENTRY POINT
################################################################################

#
# Change UID
#
if ! set | grep '^NEW_UID=' >/dev/null 2>&1; then
	log "warn" "\$NEW_UID not set"
	log "warn" "Keeping user '${ACTORDB_USER}' with default uid: ${ACTORDB_UID}"
else
	if ! isint "${NEW_UID}"; then
		log "err" "\$NEW_UID is not an integer: '${NEW_UID}'"
		exit 1
	else
		log "info" "Changing user '${ACTORDB_USER}' uid to: ${NEW_UID}"
		run "usermod -u ${NEW_UID} ${ACTORDB_USER}"
	fi
fi

#
# Change GID
#
if ! set | grep '^NEW_GID=' >/dev/null 2>&1; then
	log "warn" "\$NEW_GID not set"
	log "warn" "Keeping group '${ACTORDB_GROUP}' with default gid: ${ACTORDB_GID}"
else
	if ! isint "${NEW_GID}"; then
		log "err" "\$NEW_GID is not an integer: '${NEW_GID}'"
		exit 1
	else
		if _group_line="$( getent group "${NEW_GID}" )"; then
			_group_name="$( echo "${_group_line}" | awk -F':' '{print $1}' )"
			if [ "${_group_name}" != "${ACTORDB_GROUP}" ]; then
				log "warn" "Group with ${NEW_GID} already exists: ${_group_name}"
				log "info" "Changing GID of ${_group_name} to 9999"
				run "groupmod -g 9999 ${_group_name}"
			fi
		fi

		log "info" "Changing group '${ACTORDB_GROUP}' gid to: ${NEW_GID}"
		run "groupmod -g ${NEW_GID} ${ACTORDB_GROUP}"
	fi
fi

################################################################################
# INSTALLATION
################################################################################

#
# Fix ownership.
#
run "chown -R ${ACTORDB_USER}:${ACTORDB_GROUP} /var/lib/actordb"
run "chown -R ${ACTORDB_USER}:${ACTORDB_GROUP} /etc/actordb"
run "chown -R ${ACTORDB_USER}:${ACTORDB_GROUP} /var/log/actordb"

#
# Update node name.
#
if [ ! -f /etc/actordb/vm.args ]; then
	log "err" "/etc/actordb/vm.args not found!!!"
	exit 1
fi

if ! set | grep '^ACTORDB_NODE=' >/dev/null 2>&1; then
	log "warn" "\$ACTORDB_NODE not set"
	log "warn" "Using node name from /etc/actordb/vm.args"
else
	sed -i "s/^-name .*$/-name ${ACTORDB_NODE}/" /etc/actordb/vm.args
	log "info" "Updated node name to ${ACTORDB_NODE} in /etc/actordb/vm.args"
fi

#
# Start
#
exec actordb foreground
