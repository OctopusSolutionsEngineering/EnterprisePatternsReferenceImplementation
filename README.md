# Welcome

This repo contains the code required to start and configure a local Octopus installation demonstrating common
enterprise deployment patterns. It is based around Docker Compose and Terraform, and has been designed to allow
the Octopus stack to be created and destroyed with ease.

# Getting Started

Start the Octopus and Git stack with the following command. Any missing tools or undefined environment variables will
be reported before the setup can start:

```bash
./initdemo.sh
```

Shut the Octopus and Git stack down with:

```bash
./cleanup.sh
```

## Common Prerequisites
Windows users should run this script in WSL.

You must have [Docker](https://docs.docker.com/get-docker/) installed.

You also require these additional dependencies:

* Octopus CLI
* curl
* Terraform
* Minikube
* Openssl
* jq

These are installed in Ubuntu with the following script (to be run as root):

```
apt-get update
apt-get install -y openssl jq gnupg curl ca-certificates apt-transport-https wget
curl -sSfL https://apt.octopus.com/public.key | apt-key add - && sh -c "echo deb https://apt.octopus.com/ stable main > /etc/apt/sources.list.d/octopus.com.list" && apt update && apt install -y octopuscli
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt update && apt-get install -y terraform
if [ ! -f /usr/local/bin/kubectl ]; then curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; fi
if [ ! -f /usr/local/bin/minikube ]; then curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; install minikube-linux-amd64 /usr/local/bin/minikube; fi
```

## Octonaught Prerequisites

Copy the contents of the shared note called `Sample environment vars for EnterprisePatternsReferenceImplmenetation` in
the password manager to `~/.profile` (for Linux) or `~/.zshrc` (for macOS).

## External User's Prerequisites

You must define the following environment variables:

* `OCTOPUS_SERVER_BASE64_LICENSE` - set to a base 64 encoded Octopus license in the  environment variable.
* `TF_VAR_docker_username` - set to you DockerHub username.
* `TF_VAR_docker_password` - set to your DockerHub password.
* `TF_VAR_azure_application_id` - set to your Azure application ID.
* `TF_VAR_azure_subscription_id` - set to your Azure subscription ID.
* `TF_VAR_azure_password` - set to your Azure password.
* `TF_VAR_azure_tenant_id` - set to your Azure tenant ID.

Typically, this is done by adding the following like to `~/.profile` (for Linux) or `~/.zshrc` (for macOS):

```
export OCTOPUS_SERVER_BASE64_LICENSE=PExpY2Vuc2UgU2lnbmF0dXJlPSJk...
export TF_VAR_docker_username=your_dockerhub_username
export TF_VAR_docker_password=your_dockerhub_password
export TF_VAR_azure_application_id=your_azure_application_id
export TF_VAR_azure_subscription_id=your_azure_subscription_id
export TF_VAR_azure_password=your_azure_password
export TF_VAR_azure_tenant_id=your_azure_tenant_id
```

## Optional Settings

Set these environment variables if you want the Slack incident channel runbook to work:

* `TF_VAR_slack_bot_token` - set to a [Slack bot token](https://api.slack.com/authentication/basics) (i.e. a token starting with `xoxb-`).
* `TF_VAR_slack_support_users` - set to the comma separated list of Slack user IDs that will be pulled into the incident channels.