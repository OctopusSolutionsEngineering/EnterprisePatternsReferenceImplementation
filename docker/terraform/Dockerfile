# This Dockerfile creates an image that can be used as a worker container. It includes the latest version of Terraform
# and all the Octopus plugins prepopulated in a filesystem mirror.
# Published as octopussamples/terraform-worker-with-octopus-provider
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y gnupg software-properties-common wget jq curl unzip
# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y terraform
# Prepopulate terraform plugin cache with Octopus terraform provider versions
RUN RELEASES=$(curl --silent https://api.github.com/repos/OctopusDeployLabs/terraform-provider-octopusdeploy/releases | jq -r ".[] | .name[1:]"); echo $RELEASES; for RELEASE in ${RELEASES}; do echo "Downloading https://github.com/OctopusDeployLabs/terraform-provider-octopusdeploy/releases/download/v${RELEASE}/terraform-provider-octopusdeploy_${RELEASE}_linux_amd64.zip"; mkdir -p "/terraformcache/registry.terraform.io/octopusdeploylabs/octopusdeploy/${RELEASE}/linux_amd64"; cd "/terraformcache/registry.terraform.io/octopusdeploylabs/octopusdeploy/${RELEASE}/linux_amd64"; if [ ! -f "terraform-provider-octopusdeploy_v${RELEASE}" ]; then curl --silent -L -o "terraform-provider-octopusdeploy_${RELEASE}_linux_amd64.zip" "https://github.com/OctopusDeployLabs/terraform-provider-octopusdeploy/releases/download/v${RELEASE}/terraform-provider-octopusdeploy_${RELEASE}_linux_amd64.zip"; unzip "terraform-provider-octopusdeploy_${RELEASE}_linux_amd64.zip"; rm "terraform-provider-octopusdeploy_${RELEASE}_linux_amd64.zip"; fi; done
RUN echo "provider_installation {\nfilesystem_mirror {\npath = \"/terraformcache\"\ninclude = [\"registry.terraform.io/octopusdeploylabs/octopusdeploy\"]\n}\n}" > ~/.terraformrc