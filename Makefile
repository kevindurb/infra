install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

vagrant_up:
	vagrant up

vagrant_deploy:
	ansible-playbook -i ./inventory/vagrant ./playbooks/deploy.yaml

production_deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

build_containers:
	docker build -t kevindurb/infra_freshrss ./containers/freshrss
	docker build -t kevindurb/infra_grafana ./containers/grafana
	docker build -t kevindurb/infra_nodered ./containers/nodered
	docker build -t kevindurb/infra_ping_exporter ./containers/ping_exporter
	docker build -t kevindurb/infra_prometheus ./containers/prometheus
	docker build -t kevindurb/infra_traefik ./containers/traefik

docker_compose_dev:
	docker-compose --file ./docker-compose.yaml --file ./docker-compose.dev.yaml up --build

containers/traefik/.htpasswd:
	htpasswd -c ./containers/traefik/.htpasswd kevindurb

containers/traefik/cert.crt:
	openssl req -newkey rsa:4096 \
		-x509 \
		-sha256 \
		-days 3650 \
		-nodes \
		-out containers/traefik/cert.crt \
		-keyout containers/traefik/cert.key

clean:
	vagrant destroy -f
	docker-compose rm -f

.PHONY: install_deps vagrant_up build_containers deploy_stack setup_swarm docker_compose_dev
