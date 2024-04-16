export KIND_EXPERIMENTAL_PROVIDER := "podman"
bitwarden_item_id := 'f426c6bc-8030-4a36-9393-b00e0135beca'

install:
    ansible-galaxy install -r ./roles/requirements.yml
    npm install

update-nodes:
    ansible-playbook \
      -i ./inventory/production.yml \
      ./playbooks/provision_k3snode.yml

provision-k3snode node_name:
    ansible-playbook \
      -i ./inventory/production.yml \
      -l {{ node_name }} \
      ./playbooks/provision_k3snode.yml

mk service image="<<image>>":
    ./scripts/mk_service.sh -i {{ image }} {{ service }}

apply:
    kubectl apply -k ./

lint:
    npx prettier -w .

refresh-argo:
    hurl ./hurl/argo-webhook.hurl
