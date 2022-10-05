#!/bin/sh

function installGatewayCRDs() {
    echo ">>> Installing Kubernetes Gateway API CRDs...."
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v0.2.0-rc2/gatewayapi-crds.yaml | sed 's/^/      /'
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
    echo ">>> Kubernetes Gateway API CRDs successfully installed."
}

function runNamespacedGateways() {
  echo ">>> Deploying namespaced Gateways..."
  kubectl apply -f "namespaced/two-namespaces/cluster.yaml"
  max=2
  for i in `seq 1 $max`
  do
    NAMESPACE="envoy-gateway-system-$i"
    echo $NAMESPACE
    kubectl apply -f "namespaced/two-namespaces/envoy-gateway-$i.yaml"
  done
}

function runProxies() {
  echo ">>> Deploying proxies"
  max=2
  for i in `seq 1 $max`
  do
    NAMESPACE="envoy-gateway-system-$i"
    kubectl apply -f "namespaced/gateways/gateway-$i.yaml"
  done
}

function deployServices() {
    echo ">>> Deploying services"
    max=2
    for i in `seq 1 $max`
    do
      kubectl apply -f "namespaced/services/service-$i.yaml"
    done
}

function deployHttpRoutes() {
    echo ">>> Deploying Http Routes"
    max=2
    for i in `seq 1 $max`
    do
      NAMESPACE="envoy-gateway-system-$i"
      n=10
      for j in `seq $n`
      do
        NAME="httpbin$j"
        kubectl apply -f - << EOF
        apiVersion: gateway.networking.k8s.io/v1alpha2
        kind: HTTPRoute
        metadata:
          name: $NAME
          namespace: $NAMESPACE
        spec:
          parentRefs:
            - name: eg
          hostnames:
            - "www.$NAME$NAMESPACE.com"
          rules:
            - backendRefs:
                - group: ""
                  kind: Service
                  name: httpbin
                  port: 80
                  weight: 1
              matches:
                - path:
                    type: PathPrefix
                    value: /
EOF
      done
    done 
}

# installGatewayCRDs
# deployServices
# runProxies
# deployHttpRoutes
runNamespacedGateways