#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
set -o xtrace

STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"

OPERATOR_IMAGE=registry.connect.redhat.com/seldonio/seldon-deploy-operator
DEPLOY_IMAGE=registry.connect.redhat.com/seldonio/seldon-deploy
LOADTEST_IMAGE=registry.connect.redhat.com/seldonio/seldon-loadtester
ALIBIDETECT_IMAGE=registry.connect.redhat.com/seldonio/alibi-detect-server
REQUESTLOGGER_IMAGE=registry.connect.redhat.com/seldonio/seldon-request-logger
KUBECTL_IMAGE=registry.connect.redhat.com/seldonio/kubectl
BATCH_PROC_IMAGE=registry.connect.redhat.com/seldonio/seldon-batch-processor
MINIO_CLIENT_IMAGE=registry.connect.redhat.com/seldonio/mc-ubi


function update_images {
  # some versions hardcoded because can be different!
  # can't just align them as seldon core versions could clash (e.g. 1.0.0)

  # there are two seds for each, first is for references in alm-examples (matched by including quotes)
  # some have a comma and some don't - this depends on their position in hte alm-examples json (unnecessary trailing commas will fail scan)

    #this first one is actually special as it appears in containerImage and image but not in alm_examples
    sed -i 's#image: quay.io/seldon/seldon-deploy-server-operator:.*$#image: '${OPERATOR_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#containerImage: quay.io/seldon/seldon-deploy-server-operator:.*$#containerImage: '${OPERATOR_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/seldon-deploy-server-ubi:.*$#'\"${DEPLOY_IMAGE}:${VERSION}\"',''#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/seldon-deploy-server-ubi:.*$#value: '${DEPLOY_IMAGE}:${VERSION}'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/hey-loadtester-ubi:.*$#'\"${LOADTEST_IMAGE}:0.1\"'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/hey-loadtester-ubi:.*$#value: '${LOADTEST_IMAGE}:0.1'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/alibi-detect-server:.*$#'\"${ALIBIDETECT_IMAGE}:1.6.0-PR2923\"'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/alibi-detect-server:.*$#value: '${ALIBIDETECT_IMAGE}:1.6.0-PR2923'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/seldon-request-logger:.*$#'\"${REQUESTLOGGER_IMAGE}:1.7.0\"',''#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/seldon-request-logger:.*$#value: '${REQUESTLOGGER_IMAGE}:1.7.0'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/kubectl:.*$#'\"${KUBECTL_IMAGE}:1.14.3''\"',''#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/kubectl:.*$#value: '${KUBECTL_IMAGE}:1.14.3'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/seldon-core-s2i-python37:.*$#'\"${BATCH_PROC_IMAGE}:1.6.0\"'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/seldon-core-s2i-python37:.*$#value: '${BATCH_PROC_IMAGE}:1.6.0'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

    sed -i 's#"seldonio/mc-ubi:.*$#'\"${MINIO_CLIENT_IMAGE}:1.0\"'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
    sed -i 's#value: seldonio/mc-ubi:.*$#value: '${MINIO_CLIENT_IMAGE}:1.0'#' ${CSV_FOLDER}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml

}


VERSION=$1
CSV_FOLDER=packagemanifests-certified/${VERSION}
rm -rf packagemanifests-certified/${VERSION}
cp -r packagemanifests/${VERSION} packagemanifests-certified/${VERSION}
update_images