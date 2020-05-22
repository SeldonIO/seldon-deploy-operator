#!/usr/bin/env bash
#
# docker-secret.sh
#
set -o nounset
set -o errexit
set -o pipefail
set -o noclobber
set -o noglob
#set -o xtrace

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

DOCKERCREDS_FILE=${HOME}/.config/seldon/seldon-deploy/dockercreds.txt

source "${DOCKERCREDS_FILE}"
kubectl create secret docker-registry regcred \
    --namespace=$1 \
    --docker-server=index.docker.io \
    --docker-username=$DOCKER_USER \
    --docker-password=$DOCKER_PASSWORD \
    --docker-email=$DOCKER_EMAIL --dry-run -o yaml | kubectl apply -f -

