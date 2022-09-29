#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

METALLB_VERSION=v0.13.5

# Fingers crossed this is at least a /24 range
METALLB_IP_PREFIX_RANGE=$(docker network inspect kind --format '{{(index .IPAM.Config 0).Subnet}}' | sed -r 's/(.*).\/.*/\1/')
METALLB_IP_ADDRESS_RANGE=$(echo "${METALLB_IP_PREFIX_RANGE}200-${METALLB_IP_PREFIX_RANGE}250" | sed "s/\./\\\./g")

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

sed "s/METALLB_IP_ADDRESS_RANGE/${METALLB_IP_ADDRESS_RANGE}/" "${SCRIPT_DIR}/metallb-config.yaml" | kubectl apply -f -
