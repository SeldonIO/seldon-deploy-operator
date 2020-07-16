# OpenShit Operators-based Install of Seldon Deploy

 These scripts are for installing Seldon Deploy on OpenShift using certified Operators as dependencies. This means using flavours of the components intended for OpenShift and to be supported on OpenShift.

## Format

 The scripts are provided as scripts for simplicity but installations can also be run from the OpenShift UI. In that case the official steps should be used and these scripts used to adapt the config.

## Pre-requisites

An OpenShift cluster is needed. Tested on 4.3.13.

### Steps to Create Cluster

If a seldon employee go to https://cloud.redhat.com/openshift/ using credentials for  “Redhat Access Portal”

Otheriwse use try.openshift.com

From there `Create cluster → RedHat Openshift Container Platform → AWS → installer-provisioned`

Download binaries including installer

Create config for install directory e.g. clive1 - change as needed: ./openshift-install create install-config --dir=clive1 answer

Questions as follows

- public key - none
- platform - aws
- pick region not already in use (so not Paris or Ireland)
- base domain seldondev.com
- cluster name: clive1 (or whatever)
- pull secret: copy-paste after downloading from page in previous step

Edit the created config to contain:
```
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: t2.xlarge
  replicas: 4
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    aws:
      type: t2.xlarge
  replicas: 2
```
Create cluster `./openshift-install create cluster --dir=clive1`

The `oc` client is needed.

## Instructions

First do an `oc login`. Then run the install scripts in this order:

1. EFK
2. Prometheus cluster monitoring (or community operator but cluster monitoring preferred)
3. Istio
4. Knative-serving
5. Knative-eventing

Next install Seldon Deploy. This is [the usual install](https://deploy.seldon.io) but with an OpenShift-specific helm values file.

In particular, kfserving should be disabled and virtualservice gateway should be `seldon-gateway.istio-system.svc.cluster.local`. Prometheus and elastic config should look like:

```
prometheus:
  seldon:
    url: "http://prometheus-operated.seldon:9090/api/v1/"
    # resource metrics may come from different prometheus than req metrics - set only if different
    resourceMetricsUrl: "https://prometheus-k8s.openshift-monitoring:9091/api/v1/"
    # see https://github.com/openshift/cluster-monitoring-operator/issues/768
    namespaceMetricName: "namespace"
    serviceMetricName: "exported_service"
    #leave below empty/commented for prom without token-based auth
    #basic auth can be handled by putting user:pass in url.
    jwtSecretName: "jwt-elastic"
    jwtSecretKey: "jwt-elastic.txt"
  knative:
    url: "http://prometheus-system-np.knative-monitoring.svc.cluster.local:8080/api/v1/"


elasticsearch:
  url: "https://elasticsearch.openshift-logging:9200"
  #leave below empty/commented for elastic without token-based auth
  #basic auth can be handled by putting user:pass in urls.elasticsearch
  jwtSecretName: "jwt-elastic"
  jwtSecretKey: "jwt-elastic.txt"
```


Note that elasticsearch won't work until you login via the OpenShift UI. Have to go to `Monitoring > Logging` and just login to initialize.

The token being used for elastic is really a kubernetes service account token so in the above it is being re-used for prometheus.

Deploy should be accessible on the `/seldon-deploy/` path from the host given by `oc get route -n istio-system istio-ingressgateway -o jsonpath='{.spec.host}'`

Then setup seldon examples - seldon-iris-example and seldon-cifar10-example. For this first setup the namespace:

```
kubectl create ns seldon || true
namespace=seldon
kubectl label ns $namespace seldon.restricted=false --overwrite=true
```
And add `seldon` to the istio Member Roll from the OpenShift UI in `Installed Operators` under `istio-system`.

TODO: seldon 1.2 is needed to default the broker to seldon-logs namespace

Install the request logger. Check `kubectl get trigger -n seldon-logs` before proceeding.

Setup Seldon Deploy (namespaced and in seldon ns - need OperatorSource if not published) and then install the iris example. If not defaulted then set req logger url to http://default-broker.seldon-logs

Then run scripts from seldon-iris-example directory.

## Limitations

For now this is a single-namespace version of deploy because the [prometheus needs to be in the same namespace as the models](https://github.com/coreos/prometheus-operator/issues/3151#issuecomment-618233172). That may change with [a future version of the OpenShift prometheus](https://github.com/coreos/prometheus-operator/issues/3151#issuecomment-619026990). For now the `seldon` namespace is used for models. Also have a problem with [resource metrics](https://kubernetes.slack.com/archives/C6BRQSH2S/p1589558317200100) - seems like we need to [create a pod network link](https://stackoverflow.com/questions/42820382/how-can-two-applications-running-inside-the-openshift-send-requests-to-each-othe).

RedHat support this use of elastic and prometheus is currently unclear.
