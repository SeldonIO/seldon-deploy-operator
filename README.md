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

For KIND or other clusters without OLM, we [first install OLM](https://sdk.operatorframework.io/docs/olm-integration/quickstart-bundle/)

* Install OLM - `operator-sdk olm install`
* `make bundle` TODO: put params in makefile?
* `make bundle-build`
* `make bundle-push`
* `make bundle-validate`

Note: `make bundle` asking for params for title, description, maintainers would be a mess. Probably don't want to be doing that every time. Do we even need to?

See what core does RE: seldon-deploy-operator.clusterserviceversion.yaml and the versions there. Seems [a lot](https://github.com/SeldonIO/seldon-core/blob/master/operator/Makefile#L299)

TODO:

### Testing on OpenShift

TODO:

### Scorecard

First have a bundle built. Then `make scorecard`

TODO: this fails. Do I have to use quay as seems it can't pull from dockerhub?

## Maintaining This Project

Each new release needs to be based on the latest seldon deploy helm chart. 

TODO: see previous version but makefile has all changed