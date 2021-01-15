# Current Operator version
VERSION ?= $(shell cat version.txt)
#which replaces
REPLACES ?= $(shell cat replaces.txt)
# Default bundle image tag
BUNDLE_IMG ?= quay.io/seldon/seldon-deploy-operator-bundle:$(VERSION)
# Options for 'bundle-build'
DEFAULT_CHANNEL=stable
CHANNELS=stable,alpha
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets for operator (not bundle)
IMG ?= quay.io/seldon/seldon-deploy-server-operator:${VERSION}

opm_index:
	opm index add -c docker --bundles ${BUNDLE_IMG},quay.io/seldon/seldon-deploy-operator-bundle:v0.7.0 --tag quay.io/seldon/test-deploy-catalog:latest

opm_push:
	docker push quay.io/seldon/test-deploy-catalog:latest

.PHONY: update_openshift
update_openshift: bundle bundle-build bundle-push docker-build docker-push bundle-validate opm_index opm_push

.PHONY: create_bundle_image
create_bundle_image_%:
	docker build . -f bundle-version.Dockerfile --build-arg VERSION=$* -t quay.io/seldon/seldon-deploy-operator-bundle:v$* --no-cache

.PHONY: push_bundle_image
push_bundle_image_%:
	docker push quay.io/seldon/seldon-deploy-operator-bundle:v$*


create_bundles: docker-build docker-push create_bundle_image_1.0.0 create_bundle_image_0.7.0

push_bundles: push_bundle_image_1.0.0 push_bundle_image_0.7.0

build_push: create_bundles push_bundles

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
	docker build . -t ${IMG} --no-cache

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
	python hack/csv_hack.py --path bundle/manifests/seldon-deploy-operator.clusterserviceversion.yaml --version ${VERSION} --replaces ${REPLACES}
	mkdir -p packagemanifests/${VERSION}
	mkdir -p packagemanifests/temp
	cp bundle/manifests/* packagemanifests/temp
	mv packagemanifests/temp/seldon-deploy-operator.clusterserviceversion.yaml packagemanifests/${VERSION}/seldon-deploy-operator.v${VERSION}.clusterserviceversion.yaml
	mv packagemanifests/temp/* packagemanifests/${VERSION}
	rm -r packagemanifests/temp
	operator-sdk bundle validate ./bundle

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) . --no-cache

# Push the bundle image.
.PHONY: bundle-build
bundle-push:
	docker push $(BUNDLE_IMG)

.PHONY: bundle-build
bundle-validate:
	operator-sdk bundle validate $(BUNDLE_IMG)

scorecard:
	operator-sdk scorecard --kubeconfig ~/.kube/config $(BUNDLE_IMG)

get-helm-chart:
	./get-helm-chart.sh

apply_license_kind:
	cd ~ && kubectl create configmap -n marketplace seldon-deploy-license --from-file=./.config/seldon/seldon-deploy/license -o yaml --dry-run=client | kubectl apply -f -
	kubectl delete pod -n marketplace -l app.kubernetes.io/name=seldon-deploy || true

apply_license_openshift:
	cd ~ && kubectl create configmap -n seldon seldon-deploy-license --from-file=./.config/seldon/seldon-deploy/license -o yaml --dry-run=client | kubectl apply -f -
	kubectl delete pod -n seldon -l app.kubernetes.io/name=seldon-deploy || true

open_kind:
	xdg-open http://localhost:8080/seldon-deploy/; \
	kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80

open_cluster_with_istio:
	ISTIO_INGRESS=$$(oc get route -n istio-system istio-ingressgateway -o jsonpath='{.spec.host}'); \
	xdg-open http://$$ISTIO_INGRESS/seldon-deploy/

operator-marketplace:
	./operator-marketplace.sh