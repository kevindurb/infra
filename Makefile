COMPOSE_ARGS = -f ./docker-compose.yaml

dependencies:
	ansible-galaxy install -r ./roles/requirements.yaml
	pip install -r ./requirements.txt
	pre-commit install

pull_secrets:
	./scripts/pull_secrets

deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

setup_cloudflare_dns:
	ansible-playbook ./playbooks/setup_cloudflare_dns.yaml

nextcloud_cron:
	docker exec -u www-data infra_nextcloud_1 php -f cron.php

clean:
	docker-compose $(COMPOSE_ARGS) down -v --remove-orphans
