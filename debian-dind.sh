#!/bin/bash

set -o pipefail
set -o functrace

RED=$(tput setaf 1)
YELLOW=$(tput setaf 2)
RESET=$(tput sgr0)
DESC="Script Description"

trap '__trap_error $? $LINENO' ERR 2>&1

function __trap_error() {
	echo "Error! Exit code: $1 - On line $2"
}

function help() {
	me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
	echo
	echo $DESC
	echo
	echo "List of functions in $YELLOW$me$RESET script: "
	echo
	list=$(declare -F | awk '{print $NF}' | sort | egrep -v "^_")
	for i in ${list[@]}
	do
		echo "Usage: $YELLOW./$me$RESET$RED $i $RESET"
	done
	echo
}

CNT_NAME="debian_dind"
IMAGE="ghcr.io/manprint/debian-dind:bullseye-slim"

function __mkdir() {
	mkdir -vp $(pwd)/data/docker
	mkdir -vp $(pwd)/data/debian
}

function __volumes() {
	docker volume create \
    --driver local \
    --opt type=none \
    --opt device=$(pwd)/data/docker \
    --opt o=bind \
    vol_${CNT_NAME}_docker
	docker volume create \
    --driver local \
    --opt type=none \
    --opt device=$(pwd)/data/debian \
    --opt o=bind \
    vol_${CNT_NAME}_debian
}

function down() {
	docker stop $CNT_NAME
	docker rm $CNT_NAME
	docker volume rm vol_${CNT_NAME}_docker vol_${CNT_NAME}_debian
}

function up() {
	down
	__mkdir
	__volumes
	docker run -dit \
		--name=${CNT_NAME} \
		--hostname=debian.local \
		--privileged \
		-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
		-v vol_${CNT_NAME}_docker:/var/lib/docker \
		-v vol_${CNT_NAME}_debian:/home/debian \
		-p 2375:2375 \
		${IMAGE}
}

if [ "_$1" = "_" ]; then
	help
else
	"$@"
fi
