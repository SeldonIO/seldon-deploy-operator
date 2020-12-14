# Current Operator version
VERSION ?= $(shell cat version.txt)
# Default bundle image tag
BUNDLE_IMG ?= quay.io/seldon/seldon-deploy-operator-bundle:$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= quay.io/seldon/seldon-deploy-server-operator:${VERSION}

opm_index:
	opm index add -c docker --bundles ${BUNDLE_IMG} --tag quay.io/seldon/test-deploy-catalog:latest

opm_push:
	docker push quay.io/seldon/test-deploy-catalog:latest

.PHONY: update_openshift
update_openshift: bundle bundle-build bundle-push bundle-validate opm_index opm_push

.PHONY: operator-marketplace
operator-marketplace:
	mkdir -p tempresources
	if [ ! -d "tempresources/operator-marketplace" ]; then git clone git@github.com:operator-framework/operator-marketplace.git tempresources/operator-marketplace; fi
	kubectl apply -f tempresources/operator-marketplace/deploy/upstream/

all: docker-build

# Run against the configured Kubernetes cluster in ~/.kube/config
run: helm-operator
	$(HELM_OPERATOR) run

# Install CRDs into a cluster
install: kustomize
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall: kustomize
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: kustomize
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | kubectl delete -f -

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}

PATH  := $(PATH):$(PWD)/bin
SHELL := env PATH=$(PATH) /bin/sh
OS    = $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH  = $(shell uname -m | sed 's/x86_64/amd64/')
OSOPER   = $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCHOPER = $(shell uname -m )

kustomize:
ifeq (, $(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | tar xzf - -C bin/ ;\
	}
KUSTOMIZE=$(realpath ./bin/kustomize)
else
KUSTOMIZE=$(shell which kustomize)
endif

helm-operator:
ifeq (, $(shell which helm-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v1.2.0/helm-operator-v1.2.0-$(ARCHOPER)-$(OSOPER) ;\
	mv helm-operator-v1.2.0-$(ARCHOPER)-$(OSOPER) ./bin/helm-operator ;\
	chmod +x ./bin/helm-operator ;\
	}
HELM_OPERATOR=$(realpath ./bin/helm-operator)
else
HELM_OPERATOR=$(shell which helm-operator)
endif

# Generate bundle manifests and metadata, then validate generated files.
.PHONY: bundle
bundle: kustomize
	rm -r bundle
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	python hack/csv_hack.py --path bundle/manifests/seldon-deploy-operator.clusterserviceversion.yaml --version ${VERSION}
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

# Push the bundle image.
.PHONY: bundle-build
bundle-push:
	docker push $(BUNDLE_IMG)

.PHONY: bundle-build
bundle-validate:
	operator-sdk bundle validate $(BUNDLE_IMG)

scorecard:
	operator-sdk scorecard --kubeconfig ~/.kube/config $(BUNDLE_IMG)

apply_license:
	cd ~ && kubectl create configmap -n marketplace seldon-deploy-license --from-file=./.config/seldon/seldon-deploy/license -o yaml --dry-run=client | kubectl apply -f -
	kubectl delete pod -n marketplace -l app.kubernetes.io/name=seldon-deploy || true

open_kind:
	xdg-open http://localhost:8080/seldon-deploy/; \
	kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80