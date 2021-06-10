#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
set -o xtrace

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

VERSION=$(cat version.txt)
SELDON_DEPLOY_VERSION="v"$VERSION

TEMPRESOURCES=${STARTUP_DIR}/tempresources

rm -rf ${TEMPRESOURCES}
rm -rf ${STARTUP_DIR}/helm-charts
mkdir -p ${TEMPRESOURCES}
cd ${TEMPRESOURCES}

git clone git@github.com:SeldonIO/seldon-deploy.git
cd seldon-deploy
git fetch --tags
git checkout ${SELDON_DEPLOY_VERSION}
cd ${STARTUP_DIR}

cp -r ${TEMPRESOURCES}/seldon-deploy/tools/seldon-deploy-install/sd-setup/helm-charts ${STARTUP_DIR}/helm-charts
cp ${STARTUP_DIR}/helm-charts/seldon-deploy/values-redhat.yaml ${STARTUP_DIR}/helm-charts/seldon-deploy/values.yaml
rm ${STARTUP_DIR}/helm-charts/seldon-deploy/values-redhat.yaml
