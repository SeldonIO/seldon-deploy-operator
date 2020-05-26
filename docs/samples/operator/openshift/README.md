# Openshift Install

Follow https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md#testing-operator-deployment-on-kubernetes

Push image to Quay using base folder Makefile.

```
make quay-push
```

Add Source

```
kubectl create -f operator-source.yaml
```

Install via custom operator on admin Openshift UI console.