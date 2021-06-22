FLAGS=-i ./inventory/vagrant

install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

vagrant_up:
	vagrant up

build_containers:
	docker build -t kevindurb/infra_traefik ./containers/traefik
	docker build -t kevindurb/infra_nodered ./containers/nodered
	docker build -t kevindurb/infra_freshrss ./containers/freshrss

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up --build

containers/traefik/.htpasswd:
	htpasswd -c ./containers/traefik/.htpasswd kevindurb

clean:
	vagrant destroy -f
	docker-compose rm -f

.PHONY: install_deps vagrant_up build_containers deploy_stack setup_swarm docker_compose_dev
