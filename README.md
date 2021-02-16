# Seldon Deploy Operator

This operator can be used for installing instances of Seldon Deploy. Built with operator-sdk.

## Building

To build and push just the operator:
```bash
make docker-build
make docker-push
```
To also build and push the bundle:
```bash
make update_openshift
```

## Testing

### KIND Full Deploy Stack

To test in KIND with entire stack:

* First run kind-setup.sh from seldon-deploy repo.
* Next run `make install`
* Then `make deploy`
* Then `kubectl apply -n seldon-system -f ./examples-testing/kind-full-setup.yaml`
* Then `make open_kind`

### KIND no dependencies

This is a minimal setup just for checking installation. No Deploy features work.

* `kind create cluster`
* `make install`
* `make deploy`
* `kubectl apply -n seldon-system -f ./examples-testing/kind-minimal-setup.yaml`
*  Port-forward to deploy to see UI, though you can't deploy anything in this setup.

### OLM Deployment

First need a cluster e.g. `kind create cluster`.

For KIND or other clusters without OLM, we [first install OLM](https://sdk.operatorframework.io/docs/olm-integration/quickstart-bundle/)

* Install OLM - `operator-sdk olm install` (tested with 0.17)

* Install marketplace - `make operator-marketplace`

Now [create](https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/creating-the-metadata-bundle), push and [validate the bundle](https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/creating-the-csv)

* All done in `make update_openshift`

Create a catalog_source

```bash
kubectl create -f tests/catalog-source.yaml
```

Check

```
kubectl get catalogsource seldon-deploy-catalog -n marketplace -o yaml
```

Create operator group

```bash
kubectl create -f tests/operator-group.yaml
```

Create Subscription

```bash
kubectl create -f tests/operator-subscription.yaml
```
Check the Subscription and CSV:
```bash
kubectl get subscriptions.operators.coreos.com -n marketplace seldon-deploy-operator-subsription -o yaml
kubectl get ClusterServiceVersion -n marketplace
```
Note here the operator will be namespace only ((OwnNamespace mode)[https://catalog.redhat.com/software/operators/detail/5f0f35842991b4207fcdb202/deploy]) so will only manage SeldonDeploy instances in marketplace namespace.

Now we create a deploy instance.

* `kubectl create ns seldon-logs || true`
* `kubectl apply -n marketplace -f ./examples-testing/kind-minimal-setup.yaml` (or full if stack is present, see above for `kind-full-setup.yaml`)

If using `kind-minimal-setup.yaml` then this is all you can do.

If using the full stack then we can run demos. We'll need to apply a license, either in the UI or using `make apply_license_kind`. Open with `make open_kind`

### Testing on OpenShift

Before testing a new version make sure `make update_openshift` has been run.

Create catalog source
```bash
kubectl create -f tests/catalog-source-openshift.yaml
```
Check
```bash
kubectl get catalogsource seldon-deploy-catalog -n openshift-marketplace -o yaml
```
Choose the operator in the UI. Be sure to get the right version.

If clusterwide then check with:
```bash
kubectl get subscriptions.operators.coreos.com -n openshift-operators seldon-deploy-operator -o yaml
```
Adjust namespace if not clusterwide.

Use [installation google doc](https://docs.google.com/document/d/1Z1mYh0ZlNWHypgqVD64y6rAq0Bz6WW_LFXc0D0Big74/edit?usp=sharing) for setting up dependencies or running minimal version.

Test as applicable e.g. using Deploy demos.

Note you can only test a demo if you've got the necessary dependencies. So not batch as there are [limitations for argo and minio](https://github.com/SeldonIO/seldon-deploy-operator/issues/13)


### Scorecard

First have a bundle built. Then `make scorecard`

TODO: this fails. Do I have to use quay as seems it can't pull from dockerhub?

## Maintaining This Project


### Testing on OpenShift

There are multiple ways to setup OpenShift clusters but we have a [preferred method for seldon test clusters](https://seldonio.atlassian.net/wiki/spaces/COMPANY/pages/159318256/Creating+an+Openshift+cluster).

### Pushing Images

To push images you need `~/.config/seldon/seldon-core/redhat-image-passwords.sh` configured. Get from [1password](https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=f4hgces2dvxqirpcsir2uiqbe4&v=65l42gglwnfjheao6fu4pmxeti)

### Publishing Images of Dependencies

Images are published with Makefiles but some in core, some deploy and some here. See IMAGES.md for details.

Note that the Makefile commands are only part of it. You also have to press 'publish' in the Red Hat UI.

If you need a new image for a new component then that's a new project and requires filling out a form for Red Hat.

### Publishing Operator

Each new release needs to be based on the latest seldon deploy helm chart. The makefile references a get-helm-chart script for this.

Note that the makefile refers to a particular version in version.txt.

There are separate folders for certified vs not certified versions. This is because certified has to be hosted in redhat container registry and approved so can't iterate so fast on that.

Otherewise the operator is itself an image. It's just a special type of project in the RH UI with its own special checks.

A good walkthrough is https://redhat-connect.gitbook.io/partner-guide-for-red-hat-openshift-and-container/certify-your-operator/certify-your-operator-bundle-image/creating-operator-bundle-image-project

### Publishing Docs

The listing is maintained in https://www.ibm.com/marketplace/workbench/provider/dashboard

There is meant to be equivalent to https://marketplace.redhat.com/partner/products/9697de171a307b0dce64e423c2d7946a

But for me only IBM system works.

I think you have to create an account with IBM.

I've been chatting with Kamaldeep Singh Sehmbey via cognitive-app.slack.com

Note it needs markdown https://docs.google.com/document/d/1a_KHXZI4H_2-CdJl89ejB_zGNsq_gCDDmD6jMCsF3gc/edit?usp=sharing

### Troubleshooting Publication Issues

If you hit a bug in the Red Hat systems then raise an issue via https://connect.redhat.com/support/technology-partner/

We also have a slack channel and some direct contacts.