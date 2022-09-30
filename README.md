# Curiefense WAF + Emissary Ingress POC

Clone the repository with the following command:

```shell
git clone --recurse-submodules https://github.com/sagikazarmark/curiefense-emissary-poc.git
```

## Preparations

Build container image:

```shell
docker build .
```

If you use Kind (proceed to the instructions below if you are here for the first time),
you can build a local image and load into Kind:

```shell
docker build -t curiefense-emissary .
kind load docker-image curiefense-emissary:latest
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

kubectl apply -f curiefense/secret.yaml

cd curiefense/curiefense-helm/curiefense-helm
DOCKER_TAG=v1.5.0 ./deploy.sh -f curiefense/use-minio.yaml --set "global.proxy.frontend=envoy" --set "global.settings.curiefense_minio_insecure=true"
cd -
```

TODO: quality of life improvement: push (prod) chart to a chart repo? Use Kustomize to install components (uiserver, confserver) separately?

### Deploy Emissary Ingress

Deploy Emissary:

```shell
# If you run into any error, run it again
kustomize build emissary | k apply -f -

kubectl -n emissary wait --for condition=available --timeout=90s deploy emissary-ingress
```

### Deploy the echo app

```shell
kubectl apply -f app/app.yaml
```


## Usage

First, you might want to create some configuration that proves the system works.

For example, you could create a [Global Filter](https://docs.curiefense.io/settings/policies-rules/global-filters) that matches requests with a specific header (eg. `breakme: true`).

Check out the [documentation](https://docs.curiefense.io/settings/policies-rules) to learn about the vast number of features Curiefense has.

First, port-forward into the Curiefense UI server:

```shell
kubectl -n curiefense port-forward deploy/uiserver 8080:80
```

Then follow these steps to setup a simple deny rule:

1. Go to _Policies & Rules_
1. Choose _Global Filters_
1. Click the + (plus) sign in the right upper corner
1. Give the new filter a name
1. Add a new match for a Header (eg. `breakme: true`)
1. Choose _503 Service Unavailable_ as action
1. Hit save (floppy icon)
1. Go to _Publish Changes_
1. Hit _Publish configuration_

Next, port-forward into Emissary Ingress:

```shell
kubectl -n emissary port-forward deploy/emissary-ingress 8888:8080
```

Finally, send a request to the ingress:

```shell
curl -H "Host: host2.example.com" -H "breakme: true" localhost:8888
```

You should get an 503 from the server.


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
