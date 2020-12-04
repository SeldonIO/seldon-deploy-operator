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

TODO: minimal setup just for checking installation. No Deploy features. Worth doing?

### OLM Deployment

TODO:

### Testing on OpenShift

TODO:

### Scorecard

TODO:

## Maintaining This Project

Each new release needs to be based on the latest seldon deploy helm chart. 

TODO: see previous version but makefile has all changed