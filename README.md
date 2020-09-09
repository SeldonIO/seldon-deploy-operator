# Seldon Deploy Operator Installation

Note this directory must be named `seldon-deploy-operator`. Operator-sdk [uses the directory name](https://github.com/operator-framework/operator-sdk/issues/2333).

Tested with: 

operator-courier [2.1.7](https://github.com/operator-framework/operator-courier/issues/190)
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

1) See redhat.md in notes in seldon-deploy repo. Make sure image is published.
2) Compare the values-redhat.yaml and values.yaml in a yaml compare tool or in goland to make sure that values-redhat.yaml has every section and points to RH images.
3) Put the deploy version in get-helm-chart.sh and get the new deploy helm chart here using `make get_helm_chart`.
4) Create a new folder for the new version in the deploy/olm-catalog/seldon-deploy-operator directory - copy the contents from the previous.
5) Any differences between the new helm values file and the last one need to be reflected by updating the alm-examples section of the clusterserviceversion. It's basically a json version of a values file.
6) Make sure any references to the previous release version in what was copied are changed to the new version.
7) The clusterserviceversion contains references to images. Before publishing they should be replaced with the commented RHCR ones (search CSV for seldonio). But only when ready to publish as we can't test with those.
8) Update the version.txt, operator.yaml and osdk-scorecard.yaml to point to the new version.
9) Update PREV_VERSION in the Makefile to point to the old version.
10) Test as per the Installation section above.
11) When ready then push new image to https://connect.redhat.com/project/4805411/view
12) Zip and upload [operator metadata](https://redhat-connect.gitbook.io/partner-guide-for-red-hat-openshift-and-container/certify-your-operator/operator-metadata)

# Installation

See either `openshift-full-setup` for testing or https://docs.google.com/document/d/1Z1mYh0ZlNWHypgqVD64y6rAq0Bz6WW_LFXc0D0Big74/edit for end users.