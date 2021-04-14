FLAGS=-i ./inventory/vagrant

all: up

up:
	vagrant up

provision:
	vagrant provision

deploy_containers:
	ansible-playbook $(FLAGS) ./playbooks/deploy_containers.yaml

clean:
	vagrant destroy
