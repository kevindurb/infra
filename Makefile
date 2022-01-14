COMPOSE_ARGS = -f ./docker-compose.yaml -f ./docker-compose.metrics.yaml

install_deps:
	ansible-galaxy install -r ./roles/requirements.yaml

production_deploy:
	ansible-playbook -i ./inventory/production ./playbooks/deploy.yaml

dev_add_hosts:
	ansible-playbook -K ./playbooks/dev_add_hosts.yaml

dev_remove_hosts:
	ansible-playbook -K ./playbooks/dev_remove_hosts.yaml

nextcloud_cron:
	docker exec -u www-data infra_nextcloud_1 php -f cron.php

clean:
	docker-compose $(COMPOSE_ARGS) stop
	docker-compose $(COMPOSE_ARGS) down -v --remove-orphans
	docker-compose $(COMPOSE_ARGS) rm -fv
