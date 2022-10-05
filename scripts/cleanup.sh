#!/bin/sh

kubectl delete httproute/httpbin
kubectl delete gateway/eg
kubectl delete gc/eg
kubectl delete -f https://raw.githubusercontent.com/envoyproxy/gateway/v0.2.0-rc1/examples/kubernetes/httpbin.yaml
kubectl delete -f https://github.com/envoyproxy/gateway/releases/download/v0.2.0-rc1/install.yaml
kubectl delete -f https://github.com/envoyproxy/gateway/releases/download/v0.2.0-rc1/gatewayapi-crds.yaml


function deleteServices() {
    max=10
    for i in `seq 1 $max`
    do
        kubectl delete deployment "httpbin-$i"
    done
}

deleteServices