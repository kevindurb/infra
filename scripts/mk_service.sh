#! /bin/bash

help() {
  cat << EOF
usage: $0 <service_name>
EOF
  exit 1
}

if [ -z ${1+x} ]; then help; fi

IMAGE='<<image>>'
DRY_RUN=false
while getopts 'i:d' flag; do
  case "${flag}" in
    i) IMAGE="$OPTARG" ;;
    d) DRY_RUN=true ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done
shift $((OPTIND - 1))

SERVICE_NAME=$1
SERVICE_PATH="./services/$SERVICE_NAME"
RESOURCE_PATH="./services/$SERVICE_NAME/resources"

read -rd '' KUSTOMIZATION_YML << EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: $SERVICE_NAME-

resources:
  - ./resources/$SERVICE_NAME.yml

labels:
  - pairs:
      app.kubernetes.io/name: $SERVICE_NAME
    includeSelectors: true
    includeTemplates: true
EOF

read -rd '' RESOURCE_YML << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: $SERVICE_NAME
          image: $IMAGE
          ports:
            - name: web
              containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: service
spec:
  ports:
    - name: web
      port: 80
      targetPort: web

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: $SERVICE_NAME.durbin.casa
    cert-manager.io/cluster-issuer: cloudflare-issuer
spec:
  ingressClassName: nginx
  rules:
    - host: '$SERVICE_NAME.durbin.casa'
      http:
        paths:
          - pathType: Prefix
            path: '/'
            backend:
              service:
                name: service
                port:
                  name: web
  tls:
    - hosts:
        - $SERVICE_NAME.durbin.casa
      secretName: durbin-casa-wildcard-cert
EOF

if $DRY_RUN; then
  echo ""
  echo "mkdir -p $RESOURCE_PATH"
  echo ""
  echo "# $SERVICE_PATH/kustomization.yml"
  echo "$KUSTOMIZATION_YML"
  echo ""
  echo "# $RESOURCE_PATH/$SERVICE_NAME.yml"
  echo "$RESOURCE_YML"
else
  mkdir -p "$RESOURCE_PATH"
  echo "$KUSTOMIZATION_YML" > "$SERVICE_PATH/kustomization.yml"
  echo "$RESOURCE_YML" > "$RESOURCE_PATH/$SERVICE_NAME.yml"
fi
