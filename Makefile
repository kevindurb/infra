FLAGS=-i ./inventory/vagrant

install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

vagrant_up:
	vagrant up

build_containers:
	docker build -t kevindurb/infra_traefik ./containers/traefik
	docker build -t kevindurb/infra_nodered ./containers/nodered

deploy_stack:
	ansible-playbook $(FLAGS) ./playbooks/deploy_stack.yaml

setup_swarm:
	ansible-playbook $(FLAGS) ./playbooks/setup_swarm.yaml

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up --build

clean:
	vagrant destroy -f
	docker-compose rm -f

.PHONY: install_deps vagrant_up build_containers deploy_stack setup_swarm docker_compose_dev
