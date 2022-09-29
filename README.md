# Curiefense WAF + Emissary Ingress POC

Clone the repository with the following command:

```shell
git clone --recurse-submodules https://github.com/sagikazarmark/curiefense-emissary-poc.git
```

## Setup

Gain access to a Kubernetes cluster. Check out the [Using Kind](#using-kind) section for a local setup.


### Using Kind

1. Create a new Kind cluster:
```shell
kind create cluster --config kind/kind.yaml
```
1. Run the setup script to install required components:
```shell
./kind/setup.sh
```

### Deploy Curiefense

Deploy Curiefense:

```shell
kubectl create namespace curiefense
kubectl create namespace emissary

kubectl apply -f curiefense/example-miniocfg.yaml

cd curiefense/curiefense-helm/curiefense-helm
DOCKER_TAG=v1.5.0 ./deploy.sh -f curiefense/use-minio.yaml --set "global.proxy.frontend=envoy"
```

TODO: quality of life improvement: push (prod) chart to a chart repo? Use Kustomize to install components (uiserver, confserver) separately?

### Deploy Emissary Ingress

Deploy Emissary:

```shell
kubectl apply -f https://app.getambassador.io/yaml/emissary/3.2.0/emissary-crds.yaml
kubectl apply -f https://app.getambassador.io/yaml/emissary/3.2.0/emissary-emissaryns.yaml

kubectl -n emissary wait --for condition=available --timeout=90s deploy emissary-ingress
```

TODO: patch the deployment to use custom image.

Patch the module to add Lua config:

```shell
kubectl -n emissary patch modules.getambassador.io ambassador --type merge --patch-file emissary/module-patch.yaml
```

TODO: patch the module to add Curiefense.

TODO: add curieconf sidecar to Emissary pod?


## Usage

TODO

On Mac, you probably have to use port forwards.


## Cleanup

Ideally, delete the cluster.

In case of Kind:

```shell
kind delete cluster
```

Best effort attempt to delete resources:

```shell
kubectl delete namespace emissary
kubectl delete namespace curiefense
```
