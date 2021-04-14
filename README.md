# Infra

## Dependencies
- Vagrant
- VirtualBox
- Ansible
- make

## Usage
```
# install roles, build and provision vms
make

# reprovision vms
make provision

# deploy containers
make deploy_containers

# destroy vms
make clean
```

## Goals
- Tested
- Continuous Deployment
- Flexible
- Lightweight
