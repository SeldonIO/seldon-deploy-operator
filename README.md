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

