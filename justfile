export KIND_EXPERIMENTAL_PROVIDER := "podman"
bitwarden_item_id := 'f426c6bc-8030-4a36-9393-b00e0135beca'

install:
    ansible-galaxy install -r ./roles/requirements.yml
    npm install

provision-k3snode node_name:
    ansible-playbook \
      -i ./inventory/production.yml \
      -l {{ node_name }} \
      ./playbooks/provision_k3snode.yml

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

get-secrets:
    bw get attachment tailscale.env --itemid {{ bitwarden_item_id }} --output ./services/tailscale/tailscale.env
