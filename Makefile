install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

vagrant_up:
	vagrant up

vagrant_deploy:
	ansible-playbook -i ./inventory/vagrant ./playbooks/deploy.yaml

production_deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up

clean:
	vagrant destroy -f
	docker-compose rm -f

.PHONY: install_deps vagrant_up build_containers deploy_stack setup_swarm docker_compose_dev
