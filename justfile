export KIND_EXPERIMENTAL_PROVIDER := "podman"

create-cluster:
  kind create cluster --config ./manifests/kind.yml --name infra

delete-cluster:
  kind delete cluster --name infra
