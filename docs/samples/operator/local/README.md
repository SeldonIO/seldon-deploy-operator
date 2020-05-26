# Local Install on Kind Cluster

Create a [Kind kubernetes cluster](https://github.com/kubernetes-sigs/kind)..

```
kind create cluster
```

Use Makefile in base folder.

Install operator image on cluster.

```
make kind-image-install
```

Install CRD.

```
make yaml-install-crd
```

Install operator.

```
make yaml-install-operator 
```

Add Docker secret for Seldon Deploy.

```
./docker-registry-secret.sh seldon-system
```

Install Seldon Deploy

```
make yaml-run-seldon-deploy
```

Uninstall Seldon Deploy.

```
make yaml-delete-seldon-deploy
```

Uninstall operator

```
make yaml-uninstall-operator
```

