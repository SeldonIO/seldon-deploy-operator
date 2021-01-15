#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
set -o xtrace

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

SELDON_DEPLOY_VERSION=v0.7.0

TEMPRESOURCES=${STARTUP_DIR}/tempresources

mkdir -p ${TEMPRESOURCES}
rm -rf ${TEMPRESOURCES}/operator-marketplace

cd $TEMPRESOURCES

git clone git@github.com:operator-framework/operator-marketplace.git
cd operator-marketplace
kubectl apply -f deploy/upstream/