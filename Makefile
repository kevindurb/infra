install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

production_deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up

dev_add_hosts:
	ansible-playbook -K ./playbooks/dev_add_hosts.yaml

dev_remove_hosts:
	ansible-playbook -K ./playbooks/dev_remove_hosts.yaml

clean:
	docker-compose rm -f
