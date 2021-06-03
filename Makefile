# Current Operator version
VERSION ?= $(shell cat version.txt)
#which replaces
REPLACES ?= $(shell cat replaces.txt)
# Default bundle image tag
BUNDLE_IMG ?= quay.io/seldon/seldon-deploy-operator-bundle:v$(VERSION)
# Certified bundle image tag
BUNDLE_IMG_CERT ?= quay.io/seldon/seldon-deploy-operator-bundle-cert:v$(VERSION)
BATCH_IMG_TAG=1.9.0-dev
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
	opm index add -c docker --bundles ${BUNDLE_IMG},quay.io/seldon/seldon-deploy-operator-bundle:v1.0.0,quay.io/seldon/seldon-deploy-operator-bundle:v0.7.0 --tag quay.io/seldon/test-deploy-catalog:latest

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
	docker build . -t ${IMG} --build-arg VERSION=${VERSION} --no-cache

# Push the docker image
docker-push:
	docker push ${IMG}

#password can be found at https://connect.redhat.com/project/4805411/view
redhat-image-scan: docker-build docker-push
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_seldondeploy_operator} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag ${IMG} scan.connect.redhat.com/ospid-86da5593-9bfc-43ff-954d-0bc8dbb796f1/seldon-deploy-operator:${VERSION}
	docker push scan.connect.redhat.com/ospid-86da5593-9bfc-43ff-954d-0bc8dbb796f1/seldon-deploy-operator:${VERSION}

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
	curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v1.7.2/helm-operator-v1.7.2-$(ARCHOPER)-$(OSOPER) ;\
	mv helm-operator-v1.7.2-$(ARCHOPER)-$(OSOPER) ./bin/helm-operator ;\
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

#installs operator marketplace into a cluster
operator-marketplace:
	./operator-marketplace.sh

build-kubectl-image:
	docker build . --file=./Dockerfile.kubectl \
			--tag=seldonio/kubectl:1.14.3
push-kubectl-image:
	docker push seldonio/kubectl:1.14.3

#password can be found at https://connect.redhat.com/project/4903751/view
redhat-kubectl-image-scan: build-kubectl-image push-kubectl-image
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_kubectl} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag seldonio/kubectl:1.14.3 scan.connect.redhat.com/ospid-82f39479-3635-454f-909d-f3bd6f66fedc/kubectl:1.14.3
	docker push scan.connect.redhat.com/ospid-82f39479-3635-454f-909d-f3bd6f66fedc/kubectl:1.14.3

#note this is mc image is based on https://github.com/minio/mc/pull/2734
build-minio-image:
	docker build . --file=./Dockerfile.minioclient \
			--tag=seldonio/mc-ubi:1.0
push-minio-image:
	docker push seldonio/mc-ubi:1.0

redhat-minio-client-image-scan: build-minio-image push-minio-image
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_seldondeploy_minio_client} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag seldonio/mc-ubi:1.0 scan.connect.redhat.com/ospid-ffe3e0f1-959a-4871-803b-182742f8b59e/mc-ubi:1.0
	docker push scan.connect.redhat.com/ospid-ffe3e0f1-959a-4871-803b-182742f8b59e/mc-ubi:1.0

build-batch-proc-image:
	docker build . --file=./batchproc.Dockerfile --build-arg VERSION=$(BATCH_IMG_TAG) \
			--tag=seldonio/seldon-core-s2i-python37-cert:$(BATCH_IMG_TAG) --no-cache
push-batch-proc-image:
	docker push seldonio/seldon-core-s2i-python37-cert:$(BATCH_IMG_TAG)

redhat-batch-proc-image-scan: build-batch-proc-image push-batch-proc-image
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_seldondeploy_batch_proc} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag seldonio/seldon-core-s2i-python37-cert:$(BATCH_IMG_TAG) scan.connect.redhat.com/ospid-920169d0-d0e5-446e-8db5-614d0d75198e/seldon-batch-processor:$(BATCH_IMG_TAG)
	docker push scan.connect.redhat.com/ospid-920169d0-d0e5-446e-8db5-614d0d75198e/seldon-batch-processor:$(BATCH_IMG_TAG)

# bundle certifified images
# most of this for testing as images in RHCR can't be overwritten, have to delete them from UI, which is a pain
# certified operator image is pushed with redhat-image-scan
# certified bundle with bundle_cert_push

.PHONY: create_bundle_image_certified
create_bundle_image_certified_%:
	docker build . -f bundle-version-certified.Dockerfile --build-arg VERSION=$* -t quay.io/seldon/seldon-deploy-operator-bundle-cert:v$* --no-cache

.PHONY: packagemanifests-certified
packagemanifests-certified:
	./packagemanifests-certified.sh ${VERSION}


opm_index_certified:
	opm index add -c docker --bundles ${BUNDLE_IMG_CERT},quay.io/seldon/seldon-deploy-operator-bundle-cert:v1.0.0,quay.io/seldon/seldon-deploy-operator-bundle-cert:v0.7.0 --tag quay.io/seldon/test-deploy-catalog-cert:latest

opm_push_certified:
	docker push quay.io/seldon/test-deploy-catalog-cert:latest

.PHONY: validate_bundle_image_certified
validate_bundle_image_certified:
	operator-sdk bundle validate ${BUNDLE_IMG_CERT}

.PHONY: update_openshift_cert
update_openshift_cert: create_bundles_cert push_bundles_cert validate_bundle_image_certified opm_index_certified opm_push_certified

.PHONY: create_bundle_image
create_bundle_image_cert_%:
	docker build . -f bundle-version-certified.Dockerfile --build-arg VERSION=$* -t quay.io/seldon/seldon-deploy-operator-bundle-cert:v$* --no-cache

.PHONY: push_bundle_image
push_bundle_image_cert_%:
	docker push quay.io/seldon/seldon-deploy-operator-bundle-cert:v$*

create_bundles_cert: packagemanifests-certified create_bundle_image_cert_1.2.0 create_bundle_image_cert_1.0.0 create_bundle_image_cert_0.7.0

push_bundles_cert: push_bundle_image_cert_1.2.0 push_bundle_image_cert_1.0.0 push_bundle_image_cert_0.7.0

build_push_cert: create_bundles_cert push_bundles_cert

bundle_cert_push:
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_seldondeploy_operator_bundle} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag ${BUNDLE_IMG_CERT} scan.connect.redhat.com/ospid-b1e676a5-be95-44e9-99b4-45ea93134805/seldon-deploy-operator-bundle:${VERSION}
	docker push scan.connect.redhat.com/ospid-b1e676a5-be95-44e9-99b4-45ea93134805/seldon-deploy-operator-bundle:${VERSION}
