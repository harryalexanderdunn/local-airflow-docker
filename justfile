## Python version
PYTHON_VERSION := "3.9"

## Project info
VENV_NAME := "venv"

## Packages available from the package manager
PACKAGE_MANAGER_DEPENDENCIES := '"sed" "grep" "gawk" "python3-pip"'

## Project Setup pipeline
project-setup: package_manager_dependencies env_file virtual_env docker lazydocker-install

## install package manager dependencies
package_manager_dependencies:
	for package in {{PACKAGE_MANAGER_DEPENDENCIES}}; do \
		echo `sudo apt-get install $package`;\echo "$package installed."; \
	done

## install lazydocker
lazydocker-install:
  #!/bin/bash
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

## create virtualenv
virtual_env:
  python3 -m venv .{{ VENV_NAME }}
  ./.{{ VENV_NAME }}/bin/pip install -r requirements.txt
  @echo 'Run `source ./.{{ VENV_NAME }}/bin/activate` to activate your environment'
  @echo 'Run `deactivate` to deactivate your environment'

## Create the dotenv file for running it locally.
env_file:
  echo "AIRFLOW_UID=1000" > .env

## install libraries
install-libraries:
  ./.{{ VENV_NAME }}/bin/pip install -r requirements.txt

## uninstall libraries
uninstall-libraries:
  ./.{{ VENV_NAME }}/bin/pip uninstall -r requirements.txt

#Install docker by following the steps outlined on their website.
docker:
	sudo apt-get install ca-certificates curl gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo \
		"deb [arch="`dpkg --print-architecture`" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		"`cat /etc/os-release | sed -n 's/^VERSION_CODENAME="*\([^"]*\)"*/\1/p'`" stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo docker run hello-world
	-sudo groupadd docker
	sudo usermod -aG docker `echo $USER`
	# This echo should be before the `newgrp` command since if it's after it doesn't always work.
	echo "Test the installation with \`docker run hello-world\`. You may need to log out and back in if it doesn't work."
	-newgrp docker

# Docker container commands
clean-docker-containers:
  docker rm $(docker ps -aq)

force-remove-docker-containers:
  docker rm -vf $(docker ps -aq)

show-running-containers:
  docker ps

show-all-containers:
  docker ps -a

# Create the local app setup using docker compose.
local-airflow:
  mkdir -p ./airflow/dags
  mkdir -p ./airflow/config
  mkdir -p ./airflow/logs
  mkdir -p ./airflow/plugins
  mkdir -p ./airflow/secrets
  # chmod +r ~/.config/gcloud/application_default_credentials.json NOTE: only use this code if you are having issues with read permissions on your credentials file
  docker compose -f airflow-docker-compose.yaml build 
  docker compose -f airflow-docker-compose.yaml up airflow-init
  docker compose -f airflow-docker-compose.yaml up -d
  @echo "Run lazydocker to view the docker image running airflow"

# Create the local app setup using docker compose. Lightweight version of airflow
local-airflow-lite:
  mkdir -p ./airflow/dags
  mkdir -p ./airflow/config
  mkdir -p ./airflow/logs
  mkdir -p ./airflow/plugins
  mkdir -p ./airflow/secrets
  # chmod +r ~/.config/gcloud/application_default_credentials.json NOTE: only use this code if you are having issues with read permissions on your credentials file
  docker compose -f airflow-docker-compose-lite.yaml build 
  docker compose -f airflow-docker-compose-lite.yaml up -d
  @echo "Run lazydocker to view the docker image running airflow"

# remove containers for local airflow app once finished
destroy-airflow:
  docker compose -f airflow-docker-compose.yaml down --volumes --rmi all
  docker compose -f airflow-docker-compose.yaml down --volumes --remove-orphans

# remove containers for local airflow app once finished. Remove lightweight version containers
destroy-airflow-lite:
  docker compose -f airflow-docker-compose-lite.yaml down --volumes --rmi all
  docker compose -f airflow-docker-compose-lite.yaml down --volumes --remove-orphans
