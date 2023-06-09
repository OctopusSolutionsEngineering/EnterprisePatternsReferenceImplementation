# Welcome

This repo contains the code required to start and configure a local Octopus installation demonstrating common
enterprise deployment patterns. It is based around Docker Compose and Terraform, and has been designed to allow
the Octopus stack to be created and destroyed with ease.

## Support Levels

The process implemented by the scripts in this repo are part of a pilot programme to support platform engineering teams. It incorporates tools with varying levels of official support.

The Octopus support teams will make reasonable endeavours to support teams that wish to use this process. However, existing support Service Level Agreements (SLAs) do not apply to the tools used by this repo, 
and should not be relied on for production deployments.

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

You must have [Docker](https://docs.docker.com/get-docker/) and Docker Compose installed.

Linux users must download the Compose plugin. [This page](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)
has instructions.

You also require these additional dependencies:

* curl
* Terraform
* Minikube
* Openssl
* jq

These are installed in Ubuntu with the following script (to be run as root):

```
apt-get update
apt-get install -y openssl jq gnupg curl ca-certificates apt-transport-https wget
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt update && apt-get install -y terraform
if [ ! -f /usr/local/bin/kubectl ]; then curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; fi
if [ ! -f /usr/local/bin/minikube ]; then curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; install minikube-linux-amd64 /usr/local/bin/minikube; fi
```

## ARM macOS Prerequisites

Newer macOS users must enable the `Use Rosetta for x86/amd64 emulation on Apple Silicon` option in Docker:

![image](https://user-images.githubusercontent.com/160104/243250059-53764386-cd92-4046-a69d-57d67bb9fd09.png)


## Octonaught Prerequisites

Copy the contents of the shared note called `Sample environment vars for EnterprisePatternsReferenceImplmenetation` in
the password manager to `~/.profile` (for Linux) or `~/.zshrc` (for macOS).

## External User's Prerequisites

You must define the following environment variables:

* `OCTOPUS_SERVER_BASE64_LICENSE` - set to a base 64 encoded Octopus license in the  environment variable.
* `TF_VAR_docker_username` - set to you DockerHub username.
* `TF_VAR_docker_password` - set to your DockerHub password.

Typically, this is done by adding the following like to `~/.profile` (for Linux) or `~/.zshrc` (for macOS):

```
export OCTOPUS_SERVER_BASE64_LICENSE=PExpY2Vuc2UgU2lnbmF0dXJlPSJk...
export TF_VAR_docker_username=your_dockerhub_username
export TF_VAR_docker_password=your_dockerhub_password
```

## Optional Settings

Set these environment variables if you want the Slack incident channel runbook to work:

* `TF_VAR_slack_bot_token` - set to a [Slack bot token](https://api.slack.com/authentication/basics) (i.e. a token starting with `xoxb-`).
* `TF_VAR_slack_support_users` - set to the comma separated list of Slack user IDs that will be pulled into the incident channels.

Set these variables to complete the deployment of the sample Azure application:

* `TF_VAR_azure_application_id` - set to your Azure application ID.
* `TF_VAR_azure_subscription_id` - set to your Azure subscription ID.
* `TF_VAR_azure_password` - set to your Azure password.
* `TF_VAR_azure_tenant_id` - set to your Azure tenant ID.