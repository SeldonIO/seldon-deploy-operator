SHEL=/bin/bash
VERSION ?= $(shell cat version.txt)
PREV_VERSION=0.5.0
IMG=seldonio/seldon-deploy-operator:${VERSION}
QUAY_USER=seldon

#build image when changing helm chart templates
.PHONY: docker-build
docker-build:
	operator-sdk build ${IMG}

docker-push:
	docker push ${IMG}

#password can be found at https://connect.redhat.com/project/4805411/view
redhat-image-scan: docker-build docker-push
	source ~/.config/seldon/seldon-core/redhat-image-passwords.sh && \
		echo $${rh_password_seldondeploy_operator} | docker login -u unused scan.connect.redhat.com --password-stdin
	docker tag ${IMG} scan.connect.redhat.com/ospid-86da5593-9bfc-43ff-954d-0bc8dbb796f1/seldon-deploy-operator:${VERSION}
	docker push scan.connect.redhat.com/ospid-86da5593-9bfc-43ff-954d-0bc8dbb796f1/seldon-deploy-operator:${VERSION}


kind-image-install: docker-build
	kind load -v 3 docker-image ${IMG}

update-yaml: docker-build
	sed -i 's|image: .*|image: ${IMG}|g' deploy/operator.yaml

local-run-operator:
	operator-sdk run --local

#
# Install operator via yaml
#

yaml-install-crd:
	kubectl apply -f deploy/crds/machinelearning.seldon.io_seldondeploys_crd.yaml

yaml-install-operator:
	kubectl create ns seldon-system || echo "Namespace seldon-system already exists"
	kubectl apply -f deploy/service_account.yaml -n seldon-system
	kubectl apply -f deploy/role.yaml -n seldon-system
	kubectl apply -f deploy/role_binding.yaml -n seldon-system
	kubectl apply -f deploy/operator.yaml -n seldon-system

yaml-uninstall-operator:
	kubectl delete -f deploy/service_account.yaml -n seldon-system
	kubectl delete -f deploy/role.yaml -n seldon-system
	kubectl delete -f deploy/role_binding.yaml -n seldon-system
	kubectl delete -f deploy/operator.yaml -n seldon-system
	kubectl delete ns seldon-system

yaml-run-seldon-deploy:
	kubectl apply -f deploy/crds/machinelearning.seldon.io_v1alpha1_seldondeploy_cr.yaml -n seldon-system

yaml-delete-seldon-deploy:
	kubectl delete -f deploy/crds/machinelearning.seldon.io_v1alpha1_seldondeploy_cr.yaml -n seldon-system

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

refresh-operator-catalog:
	kubectl scale deployment seldon-operators --replicas=0 -n openshift-marketplace
	kubectl scale deployment seldon-operators --replicas=1 -n openshift-marketplace
#
# Bundle and CSV
# Still using package manifests: see https://github.com/operator-framework/operator-sdk/issues/3079
#

generate-csv:
	operator-sdk generate csv --csv-version ${VERSION} --make-manifests=false --verbose

#bundle is future way, currently just using csv
generate-bundle:
	operator-sdk bundle create --generate-only --directory ./deploy/olm-catalog/seldon-deploy-operator/0.6.0/

validate-bundle:
	operator-courier verify --ui_validate_io deploy/olm-catalog/seldon-deploy-operator/

scorecard:
	kubectl create ns seldon-system || true
	operator-sdk scorecard -o text --bundle deploy/olm-catalog/seldon-deploy-operator --kubeconfig ~/.kube/config --verbose


# See https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md
# Used to push bundle to quay.io for testing
quay-push:
	operator-courier push deploy/olm-catalog/seldon-deploy-operator ${QUAY_USER} seldon-deploy-operator ${VERSION} "$$QUAY_TOKEN"


helm-install:
	./sd-install-openshift

helm-delete:
	helm delete seldon-deploy -n seldon

#
# install operator for OLM
#

olm-install:
	operator-sdk olm install

olm-verify:
	operator-sdk olm status

olm-install-operator:
	operator-sdk run --olm --operator-version ${VERSION}

olm-cleanup-operator:
	operator-sdk cleanup --olm --operator-version ${VERSION}


open_cluster_with_istio:
	ISTIO_INGRESS=$$(oc get route -n istio-system istio-ingressgateway -o jsonpath='{.spec.host}'); \
	xdg-open http://$$ISTIO_INGRESS/seldon-deploy/