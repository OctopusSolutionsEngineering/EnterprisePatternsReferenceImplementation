# Getting Started

Set the `OCTOPUS_SERVER_BASE64_LICENSE` environment variable to a base 64 encoded copy of your Octopus license key. This
is passed through to the Octopus instances launched by Docker.

Ensure you have the [Octopus CLI](https://octopus.com/downloads/octopuscli) tool installed.

You will also need DockerHub credentials. You will be prompted to add the DockerHub username and password when initializing
the Octopus instances.

Start the Octopus and Git stack with:

```bash
./initdemo.sh
```

Shut the Octopus and Git stack down with:

```bash
./cleanup.sh
```

# Goals

* Deploy unmanaged project
* Deploy managed project
* Deploy shared project
* Self-service projects
* Deploy one-to-many

# Enterprise patterns MVP

* Tenant for space

# Todo

* Create environment for synchronizing. [DONE]
* Scope runbooks to sync environment. [DONE]
* Add managed project deployment. [DONE]
* Add unmanaged project deployment. [DONE]
* Add self-service project deployment.
  * Add management instance shared variables.
  * deploy a "run a runbook" step
* Add tenants for managed spaces. [DONE]
* Link tenants to sample projects. [DONE]
* Add tenant specific octopus variables. [DONE]
* Test serialize and deploy. [DONE]
* Add CaC enabled projects. [DONE]
  * Allow CaC url to be overridden. [DONE]
  * Ignore versioning strategy for CaC enabled projects.[DONE]
* Add merge runbooks. [DONE]
* Add ocl check during merge.
* Add one-to-many project deployments. [DONE]
* Add merge all runbook
* Add merge conflict check runbook
* Add runbook variable scoping

* Create development, test/production spaces.
* Add sample project to development.
* Use variable sets for database connection string.
  * Allow variables to be ignored. [DONE]
* Add promotion runbook.