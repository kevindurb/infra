install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

production_deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

dev_add_hosts:
	ansible-playbook -K ./playbooks/dev_add_hosts.yaml

dev_remove_hosts:
	ansible-playbook -K ./playbooks/dev_remove_hosts.yaml
