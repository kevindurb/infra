export KIND_EXPERIMENTAL_PROVIDER := "podman"

install:
	ansible-galaxy install -r ./roles/requirements.yml
	pip install -r ./requirements.txt

create-cluster:
  kind create cluster --config ./cluster.yml

delete-cluster:
  kind delete cluster --name infra

apply:
  kubectl apply -k .

check:
  kubectl --dry-run=server apply -k .

lint:
  npx prettier -w .

admin-token:
  kubectl -n kubernetes-dashboard create token admin-user
