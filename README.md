# Seldon Deploy Operator

This operator can be used for installing instances of Seldon Deploy. Built with operator-sdk.

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

TODO: update chart and turn off argocd flag when https://github.com/SeldonIO/seldon-deploy/issues/1741 is done

### OLM Deployment

First need a cluster e.g. `kind create cluster`.

For KIND or other clusters without OLM, we [first install OLM](https://sdk.operatorframework.io/docs/olm-integration/quickstart-bundle/)

* Install OLM - `operator-sdk olm install` (tested with 0.17)

* Install marketplace - `make operator-marketplace`

Now [create](https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/creating-the-metadata-bundle) and [validate bundle](https://redhat-connect.gitbook.io/certified-operator-guide/ocp-deployment/operator-metadata/creating-the-csv)

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
Check the Subscription:
```bash
kubectl get subscriptions.operators.coreos.com -n marketplace seldon-deploy-operator-subsription -o yaml
```

* `kubectl apply -n seldon-system -f ./examples-testing/kind-minimal-setup.yaml` (or full if stack is present, see above)

### Testing on OpenShift

TODO:

### Scorecard

First have a bundle built. Then `make scorecard`

TODO: this fails. Do I have to use quay as seems it can't pull from dockerhub?

## Maintaining This Project

Each new release needs to be based on the latest seldon deploy helm chart. 

TODO: see previous version but makefile has all changed