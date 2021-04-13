all: up

up:
	vagrant up

provision:
	vagrant provision

clean:
	vagrant destroy
