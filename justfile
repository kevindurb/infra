install:
	ansible-galaxy install -r ./roles/requirements.yml
	pip install -r ./requirements.txt

create-cluster:
  minikube start --subnet 10.10.10.0/24

delete-cluster:
  minikube delete

apply:
  kubectl apply -k .

lint:
  npx prettier -w .
