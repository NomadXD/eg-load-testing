#!/bin/sh

function deleteHttpRoutes() {
    echo ">>> Deleting Http Routes"
    max=2
    for i in `seq 1 $max`
    do
      NAMESPACE="envoy-gateway-system-$i"
      n=10
      for j in `seq $n`
      do
        NAME="httpbin$j"
        kubectl delete httproute httpbin$j --namespace=$NAMESPACE
      done
    done 
}

function deleteProxies() {
    echo ">>> Deleting proxies"
    max=2
    for i in `seq 1 $max`
    do
      NAMESPACE="envoy-gateway-system-$i"
      kubectl delete gateway eg --namespace=$NAMESPACE
    done
}

function deleteGateways() {
    echo ">>> Deleting gateways"
    max=2
    for i in `seq 1 $max`
    do
      NAMESPACE="envoy-gateway-system-$i"
      kubectl delete -f "namespaced/two-namespaces/envoy-gateway-$i.yaml"
    done
}


# deleteProxies
deleteGateways