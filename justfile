create-cluster:
  minikube start --subnet 10.10.10.0/24

delete-cluster:
  minikube delete

apply:
  kubectl apply -k .
