#!/bin/sh

function installGatewayCRDs() {
    echo ">>> Installing Kubernetes Gateway API CRDs...."
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v0.2.0-rc1/gatewayapi-crds.yaml | sed 's/^/      /'
    echo "++++++++++++++++++++++++++++++++++++++++++++++"
    echo ">>> Kubernetes Gateway API CRDs successfully installed."
}

function runEnvoyGateway() {
    echo ">>> Starting Envoy Gateway...."
    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v0.2.0-rc1/install.yaml
    EG_GATEWAY_READY="0/1"
    while [ "$EG_GATEWAY_READY" != "1/1" ]
    do
        echo "Checking for deployment status"
        DEPLOYMENT_STATUS=$(kubectl get deployment envoy-gateway --namespace=envoy-gateway-system)
        echo "$DEPLOYMENT_STATUS"
        if echo "$DEPLOYMENT_STATUS" | grep -q "1/1"; then
            echo "Envoy gateway deployment ready"
            EG_GATEWAY_READY="1/1"
        fi
    done
}

function runHttpBinService() {
    echo ">>> Starting Httpbin echo service..."
    kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/v0.2.0-rc1/examples/kubernetes/httpbin.yaml | sed 's/^/      /'
}

function installGatewayClass() {
    echo ">>> Installing Gateway controller (GatewayClass)"
    kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/v0.2.0-rc1/examples/kubernetes/gatewayclass.yaml
    GATEWAYCLASS=$(kubectl get gatewayclass eg)
    if echo "$GATEWAYCLASS" | grep -q "True"; then
        echo "Gateway controller successfully installed"
    fi
}

function runGateway() {
    echo ">>> Starting gateway / envoy proxy"
    echo $(date -u)
    kubectl apply -f https://raw.githubusercontent.com//envoyproxy/gateway/v0.2.0-rc1/examples/kubernetes/gateway.yaml 
    GATEWAY_READY="0/1"
    while [ "$GATEWAY_READY" != "1/1" ]
    do
        echo "Checking for deployment status"
        POD_STATUS=$(kubectl get deployment envoy-eg --namespace=envoy-gateway-system)
        echo "$POD_STATUS"
        if echo "$POD_STATUS" | grep -q "1/1"; then
            echo "gateway / envoy proxy deployment ready"
            echo $(date -u)
            GATEWAY_READY="1/1"
        fi
    done
}

function deployService() {
    echo ">>> Deploying services"
    max=10
    kubectl apply -f - << EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: httpbin
      ---:
      apiVersion: v1
      kind: Service
      metadata:
        name: httpbin
        labels:
          app: httpbin
          service: httpbin
      spec:
        ports:
          - name: http
            port: 80
            targetPort: 80
        selector:
          app: httpbin
      ---:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: httpbin
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: httpbin
            version: v1
        template:
          metadata:
            labels:
              app: httpbin
              version: v1
          spec:
            serviceAccountName: httpbin
            containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                ports:
                  - containerPort: 80
EOF

}

function deployServicesBackup() {
    echo ">>> Deploying services"
    max=1000
    for i in `seq 1 $max`
    do
      echo "$i"
      NAME="httpbin-$i"
      echo "$NAME"
      kubectl apply -f - << EOF
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: httpbin
        ---:
        apiVersion: v1
        kind: Service
        metadata:
          name: $NAME
          labels:
            app: $NAME
            service: $NAME
        spec:
          ports:
            - name: http
              port: 80
              targetPort: 80
          selector:
            app: $NAME
        ---:
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: $NAME
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: $NAME
              version: v1
          template:
            metadata:
              labels:
                app: $NAME
                version: v1
            spec:
              serviceAccountName: httpbin
              containers:
                - image: docker.io/kennethreitz/httpbin
                  imagePullPolicy: IfNotPresent
                  name: httpbin
                  ports:
                    - containerPort: 80
EOF
    done

}

function deployServices() {
    echo ">>> Deploying services"
    max=1000
    for i in `seq 1 $max`
    do
      NAME="httpbin-$i"
      echo "$NAME"
      kubectl apply -f - << EOF
        apiVersion: v1
        kind: Service
        metadata:
          name: $NAME
          labels:
            app: $NAME
            service: $NAME
        spec:
          ports:
            - name: http
              port: 80
              targetPort: 80
          selector:
            app: httpbin
EOF
    done

}

function deployAPIs() {
    echo ">>> Deploying APIs"
    echo $(date -u) > logtimer.txt
    max=1000
    for i in `seq 1 $max`
    do
      echo "$i"
      NAME="route$i"
      RESOURCE="/$i"
      SERVICE="httpbin-$i"

      kubectl apply -f - << EOF
        apiVersion: gateway.networking.k8s.io/v1alpha2
        kind: HTTPRoute
        metadata:
          name: $NAME
        spec:
          parentRefs:
            - name: eg
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
                    value: $RESOURCE
EOF
    done

}

function getReconcileTime() {
  kubectl logs envoy-gateway-75fb947498-wdbl8  --namespace=envoy-gateway-system | "reconciled httproute"
}

installGatewayCRDs
runHttpBinService
installGatewayClass
deployServices
deployAPIs
runEnvoyGateway
runGateway

# kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/v0.2.0-rc1/examples/kubernetes/httproute.yaml