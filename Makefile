COMPOSE_ARGS = -f ./docker-compose.yaml

pull_secrets:
	./scripts/pull_secrets

install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

dev_add_hosts:
	ansible-playbook -K ./playbooks/dev_add_hosts.yaml

dev_remove_hosts:
	ansible-playbook -K ./playbooks/dev_remove_hosts.yaml

setup_cloudflare_dns:
	ansible-playbook ./playbooks/setup_cloudflare_dns.yaml

nextcloud_cron:
	docker exec -u www-data infra_nextcloud_1 php -f cron.php

clean:
	docker-compose $(COMPOSE_ARGS) down -v --remove-orphans
