# Seldon Deploy Operator Installation

Note this directory must be named `seldon-deploy-operator`. Operator-sdk [uses the directory name](https://github.com/operator-framework/operator-sdk/issues/2333).

Tested with: 

operator-courier 2.7.1
operator-sdk v0.17.1

First check you can run scorecard from Makefile against empty kind cluster.

Then build csv and push to quay. Have to [get token from quay](https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md#quay-login) and set QUAY_TOKEN env var in order to push.

Make the application in quay.io public so cluster can access.

If changing chart content then also build image (operator image) and push that.

Image runs the helm-based operator. [OperatorSource tells openshift about sources of operators. CSV installs the operator.](https://github.com/tmckayus/olm-testing-example)

Can then run on cluster.

## Operator Examples

 * [Local Kind cluster](docs/samples/operator/local/README.md).
 * [Operator Lifecycle Manager](docs/samples/operator/olm/README.md)
 * [Openshift cluster](docs/samples/operator/openshift/README.md)

## Maintaining This Project

Each new release needs to be based on the latest seldon deploy helm chart. The release version should match a deploy release version. This involves:

1) Updating the helm chart here.
2) Create a new folder for the new version in the deploy/olm-catalog/seldon-deploy-operator directory - copy the contents from the previous.
3) Any differences between the new helm values file and the last one need to be reflected by updating the alm-examples section of the clusterserviceversion. It's basically a json version of a values file.
4) Make sure any references to the previous release version in what was copied are changed to the new version.
5) Update the version.txt, operator.yaml and osdk-scorecard.yaml to point to the new version.
6) Update PREV_VERSION in the Makefile to point to the old version.
7) Test as per the Installation section above.
8) When ready then push new image to https://connect.redhat.com/project/4805411/view
