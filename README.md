# Seldon Deploy Operator

This operator can be used for installing instances of Seldon Deploy. Built with operator-sdk (v1.8.0).

Intended as a [Red Hat Marketplace operator](https://redhat-connect.gitbook.io/partner-guide-for-red-hat-openshift-and-container/certify-your-operator/certify-your-operator-bundle-image/creating-operator-bundle-image-project) but can be run outside openshfit.

It is a helm-based operator. So basically an image that runs helm and can install a helm chart in response to a CRD being posted. The CRD maps directly to a values file.

There are dependencies needed for running Deploy and marketplace imposes restrictions on these. See [installation google doc](https://docs.google.com/document/d/1a_KHXZI4H_2-CdJl89ejB_zGNsq_gCDDmD6jMCsF3gc/edit?usp=sharing)

## Building

Dependencies

 * [Operator SDK](https://sdk.operatorframework.io/)
   * Tested with 1.8.0


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
* `kubectl create ns seldon-logs`
* `make install`
* `make deploy`
* `kubectl apply -n seldon-system -f ./examples-testing/kind-minimal-setup.yaml`
*  Port-forward to deploy (`kubectl port-forward -n seldon-system svc/seldondeploy-sample-kind-full-seldon-deploy 8080:80`) 
[to see UI](http://localhost:8080/seldon-deploy/), though you can't deploy anything in this setup. 

### OLM Deployment

First need a cluster e.g. `kind create cluster`.

For KIND or other clusters without OLM, we [first install OLM](https://sdk.operatorframework.io/docs/olm-integration/quickstart-bundle/)

* Install OLM - `operator-sdk olm install` (tested with 1.8.0)

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
Note here the operator will be namespace only ([OwnNamespace mode](https://catalog.redhat.com/software/operators/detail/5f0f35842991b4207fcdb202/deploy)) so will only manage SeldonDeploy instances in marketplace namespace.

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

If clusterwide (initially only option) then check with:
```bash
kubectl get subscriptions.operators.coreos.com -n openshift-operators seldon-deploy-operator -o yaml
```
Adjust namespace if not clusterwide.

Use [installation google doc](https://docs.google.com/document/d/1a_KHXZI4H_2-CdJl89ejB_zGNsq_gCDDmD6jMCsF3gc/edit?usp=sharing) for setting up dependencies or running minimal version.

Test as applicable e.g. using Deploy demos. The google doc points at how to open or you can use `make open_cluster_with_istio`.

Note you can only test a demo if you've got the necessary dependencies. So not batch as there are [limitations for argo and minio](https://github.com/SeldonIO/seldon-deploy-operator/issues/13)


### Scorecard

First have a bundle built. Then `make scorecard`. But no point running this.

Problem is that it deploys the manifest from config/samples, which is the alm-examples one. That needs the dependencies.

That example is the one that shows up in marketplace. Would need RH to decouple scorecard from alm-examples to use this.

## Maintaining This Project

### Steps for Publishing a New Deploy Version

 1. First check the deploy image is published from deploy repo with `make build_image_redhat` and `make push_to_dockerhub_ubi`. Ensure you are in the release branch, e.g. `git checkout v1.2.1`
 1. This new version of the seldonio/seldon-deploy-server-ubi image should be plugged into the values file. You could plug into deploy's [values-redhat.yaml](https://github.com/SeldonIO/seldon-deploy/blob/master/tools/seldon-deploy-install/sd-setup/helm-charts/seldon-deploy/values-redhat.yaml) before release or in [seldon-deploy-operator](helm-charts/seldon-deploy/values-redhat.yaml) when copied over (later step). 
 1. Then in seldon-deploy-operator change the version in [version.txt](version.txt) and also [replaces.txt](replaces.txt) (which is the version before this).
 1.  If the target openshift version has changed then change that too (in the various bundle-*.Dockerfile files inc [bundle.Dockerfile](bundle.Dockerfile))
 1. Run `make get-helm-chart` to pull in latest helm chart. Will need to save values.yaml if you have changed this as it will be overwritten.
    * Note that the deploy image (seldonio/seldon-deploy-server-ubi) may not have been updated in the deploy [values-redhat.yaml](helm-charts/seldon-deploy/values-redhat.yaml) file (see first step) and if so you'll need to update here.
 1. If there have been changes in the values file then you'll have to update examples in examples-testing and [config/samples/machinelearning.seldon_v1alpha1_seldondeploy.yaml](config/samples/machinelearning.seldon_v1alpha1_seldondeploy.yaml)
    * [config/samples/machinelearning.seldon_v1alpha1_seldondeploy.yaml](config/samples/machinelearning.seldon_v1alpha1_seldondeploy.yaml) is best updated by copy-pasting the [values-redhat.yaml](helm-charts/seldon-deploy/values-redhat.yaml) and changing the indentation but [examples-testing](examples-testing/) files need to be updated with the specific changes
    * You can look at the history of the values file in deploy to determine what has changed since last release.
 1. Update referenced images in the values file will come across with the values file but [config/samples]((config/samples/machinelearning.seldon_v1alpha1_seldondeploy.yaml)), [examples-testing](examples-testing/), [manager.yaml](config/manager/manager.yaml) and [packagemanifests-certified.sh](packagemanifests-certified.sh) need manual update to correct image tags (see [IMAGES.md](IMAGES.md))
    * Updating the above-referenced files should cover all uses of the dependent images (those referenced in values-redhat.yaml and [IMAGES.md](IMAGES.md)) but best to search workspace for each version to make sure none missed.
 1. Update the `opm_index` and `opm_index_certified` commands in the Makefile to include the previous version in the list of images. If you don't add all versions (inc past) to its list, you'll hit `bundle specifies a non-existent replacement` error.
 1. To build and push test images for deploy operator and its bundle you can run `make update_openshift` (this is run during testing steps but can also run first).
 1.  Run through all the tests above - kind and in openshift and with marketplace and all the dependencies. Note these tests use quay/dockerhub images. The corresponding images in red hat container registry have to be approved before use.
 1. If anything has changed in an openshift version (e.g. a change to user-workload-monitoring), update the docs (see 'publishing docs' below).
 1. Before publishing update the `create_bundles_cert` and `push_bundles_cert` make targets in [Makefile](Makefile) to include the new version.
 1. Publish images except bundle - see [IMAGES.md](IMAGES.md) for how to publish (all make targets listed there).
 1. Run `make openshift_update_cert`
 1. Publish bundle except bundle - see [IMAGES.md](IMAGES.md) for how to publish
 1. Publish docs - see docs section below
 1.  After publication contact IBM (see contacts below) to confirm new version of [bundle](https://catalog.redhat.com/software/containers/seldonio/seldon-deploy-operator-bundle/5f77569a29373868204224e3) has gone to their queue 
 
 [Video explaining the above](https://us02web.zoom.us/rec/share/uUZBYABuiPJmtZU4jX67hZN8z8wy6jdbj8Tp4jAGRO_iK7kphsg1i2a3DEn-gxZ2.-dlNKTUa032I79P4)
 
### Contacts

See https://seldonio.atlassian.net/wiki/spaces/COMPANY/pages/1201078285/Tech+Contacts

### Systems Involved

RCR - redhat container registry - integrated with connect.redhat.com for publishing official images.
https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=f4hgces2dvxqirpcsir2uiqbe4&v=65l42gglwnfjheao6fu4pmxeti

connect.redhat.com - system for publishing images and bundles and other RH stuff (including raising issues with the system via https://connect.redhat.com/support/technology-partner/).
https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=pbdteciyqnp3rsxpcrkaxevftm&v=po7kyvksukhlrsurwmygolab3a

Quay.io - for test images before switching to RCR for publication (as that has manual steps).
https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=taumgl2tiapt2dnphzbugepjxy&v=65l42gglwnfjheao6fu4pmxeti

Red Hat marketplace workbench for listing documentation. You have to [go through the correct red hat marketplace partner link](https://marketplace.redhat.com/partner/products) to get to it. And sometimes you have to hit the edit button multiple times.
https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=vdgkpe3ii5bm6vkzycvw4tepni&v=po7kyvksukhlrsurwmygolab3a

cloud.redhat.com for creating clusters
https://seldonio.atlassian.net/wiki/spaces/COMPANY/pages/159318256/Creating+an+Openshift+cluster

### Testing on OpenShift

There are multiple ways to setup OpenShift clusters but we have a [preferred method for seldon test clusters](https://seldonio.atlassian.net/wiki/spaces/COMPANY/pages/159318256/Creating+an+Openshift+cluster).

### Pushing Images

To push images you need `~/.config/seldon/seldon-core/redhat-image-passwords.sh` configured. Get from [1password](https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=f4hgces2dvxqirpcsir2uiqbe4&v=65l42gglwnfjheao6fu4pmxeti)

### Publishing Images of Dependencies

Images are published with Makefiles but some in core, some deploy and some here. See [IMAGES.md](IMAGES.md) for details.

Note that the Makefile commands are only part of it. You also have to press 'publish' in the Red Hat UI.

If you need a new image for a new component then that's a new project and requires filling out a form for Red Hat.

### Publishing Operator

Each new release needs to be based on the latest seldon deploy helm chart. The makefile references a get-helm-chart script for this.

Note that the makefile refers to a particular version in version.txt.

There are separate folders for certified vs not certified versions. This is because certified has to be hosted in redhat container registry and approved so can't iterate so fast on that.

Otherewise the operator is itself an image. It's just a special type of project in the RH UI with its own special checks.

A good walkthrough is https://redhat-connect.gitbook.io/partner-guide-for-red-hat-openshift-and-container/certify-your-operator/certify-your-operator-bundle-image/creating-operator-bundle-image-project

### Publishing Docs

The listing is maintained in https://marketplace.redhat.com/partner/products/9697de171a307b0dce64e423c2d7946a
 (replacing https://www.ibm.com/marketplace/workbench/provider/dashboard)

The account for this is in [1password](https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=vdgkpe3ii5bm6vkzycvw4tepni&v=po7kyvksukhlrsurwmygolab3a)

Access management is handled at:  http://marketplace.redhat.com/en-us/account/partner-management

Note it needs markdown https://docs.google.com/document/d/1a_KHXZI4H_2-CdJl89ejB_zGNsq_gCDDmD6jMCsF3gc/edit?usp=sharing

### Updating Quickstarts

Fork https://github.com/red-hat-data-services/odh-dashboard

Create a PR to updates the [seldon quickstarts](https://github.com/red-hat-data-services/odh-dashboard/tree/master/data/quickstarts) - Usually by updating the links to new version of Deploy but might also need to change actually demo instructions. 

### Troubleshooting Publication Issues

If you hit a bug in the Red Hat systems then raise an issue via https://connect.redhat.com/support/technology-partner/

We also have a slack channel and some direct contacts.

### Common Mistakes/Issues/Gotchas

* Image vulnerability scans can sometimes take a long time - occasionally as much as 13 hrs
* Scans sometimes come back without a reason - if so raise issue https://connect.redhat.com/support/technology-partner/
* Don't worry too much about category when raising these issues - there's rarely a good one but they get re-routed
* If vulnerability scan fails without a reason it's like a base image needing updating
* Dependent images must be published first
* End user has to go through marketplace url when installing, not operatorhub (different from testing flow)
* Be careful when following RH docs - easy to miss something

