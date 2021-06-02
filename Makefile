FLAGS=-i ./inventory/vagrant

all: install_roles up

install: install_roles

install_roles:
	ansible-galaxy install -r ./roles/requirements.yaml

up:
	vagrant up

provision:
	vagrant provision

build_containers:
	docker build -t kevindurb/infra_traefik ./containers/traefik
	docker build -t kevindurb/infra_nodered ./containers/nodered

deploy_containers:
	ansible-playbook $(FLAGS) ./playbooks/deploy_containers.yaml

setup_swarm:
	ansible-playbook $(FLAGS) ./playbooks/setup_swarm.yaml

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up --build

clean:
	vagrant destroy -f
	docker-compose rm -f
