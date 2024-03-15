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

admin-token:
    kubectl -n kubernetes-dashboard create token admin-user

add-secret file:
    bw create attachment --itemid {{ bitwarden_item_id }} --file {{ file }}

get-secrets:
    bw get attachment cert-manager.env --itemid {{ bitwarden_item_id }} --output ./services/cert-manager/cert-manager.env
    bw get attachment external-dns.env --itemid {{ bitwarden_item_id }} --output ./services/external-dns/external-dns.env
    bw get attachment pihole.env --itemid {{ bitwarden_item_id }} --output ./services/pihole/pihole.env
    bw get attachment firefly.env --itemid {{ bitwarden_item_id }} --output ./services/firefly/firefly.env
    bw get attachment tandoor.env --itemid {{ bitwarden_item_id }} --output ./services/tandoor/tandoor.env
