#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
set -o xtrace

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

rm -rf packagemanifests-certified

OPERATOR_IMAGE=registry.connect.redhat.com/seldonio/seldon-deploy-operator
DEPLOY_IMAGE=registry.connect.redhat.com/seldonio/seldon-deploy
LOADTEST_IMAGE=registry.connect.redhat.com/seldonio/seldon-loadtester
ALIBIDETECT_IMAGE=registry.connect.redhat.com/seldonio/alibi-detect-server
REQUESTLOGGER_IMAGE=registry.connect.redhat.com/seldonio/seldon-request-logger
KUBECTL_IMAGE=registry.connect.redhat.com/seldonio/kubectl
#TODO: PLUG IN THE RHCR FOR BELOW WHEN CREATED
BATCH_PROC_IMAGE=seldonio/seldon-core-s2i-python37
MINIO_CLIENT_IMAGE=seldonio/mc-ubi

cp packagemanifests packagemanifests-certified


function update_images {
  # some versions hardcoded because can be different!
  # can't just align them as seldon core versions could clash (e.g. 1.0.0)

  # TODO: need to be consistent on using or not using docker.io prefix

    sed -i 's#\(^.*image: \)quay.io/seldon/seldon-deploy-server-operator:.*$#\1'${OPERATOR_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*containerImage: \)quay.io/seldon/seldon-deploy-server-operator:.*$#\1'${OPERATOR_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)docker.io/seldonio/seldon-deploy-server-ubi:.*$#\1'${DEPLOY_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)docker.io/seldonio/hey-loadtester-ubi:.*$#\1'${LOADTEST_IMAGE}:0.1'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)docker.io/seldonio/alibi-detect-server:.*$#\1'${ALIBIDETECT_IMAGE}:1.5.1'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)docker.io/seldonio/seldon-request-logger:.*$#\1'${REQUESTLOGGER_IMAGE}:1.5.1'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)docker.io/seldonio/kubectl:.*$#\1'${KUBECTL_IMAGE}:1.14.3'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)seldonio/seldon-core-s2i-python37:.*$#\1'${BATCH_PROC_IMAGE}:1.5.1'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml
    sed -i 's#\(^.*value: \)seldonio/mc-ubi:.*$#\1'${MINIO_CLIENT_IMAGE}:1.0'#' ${CSV_FOLDER}/seldon-deploy-operator.clusterserviceversion.yaml

}


VERSION=$1
CSV_FOLDER=packagemanifests-certified/${VERSION}
update_images